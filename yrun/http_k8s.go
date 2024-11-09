package yrun

import (
	"context"
	"fmt"
	"log/slog"
	"maps"
	"net"
	"os"
	"path"
	"runtime/debug"
	"slices"
	"strconv"
	"time"

	apicorev1 "k8s.io/api/core/v1"
	apimetav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	applycorev1 "k8s.io/client-go/applyconfigurations/core/v1"
	applymetav1 "k8s.io/client-go/applyconfigurations/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	gwapplyv1 "sigs.k8s.io/gateway-api/apis/applyconfiguration/apis/v1"
	gwapiv1 "sigs.k8s.io/gateway-api/apis/v1"
	gwclientv1 "sigs.k8s.io/gateway-api/pkg/client/clientset/versioned/typed/apis/v1"
)

func ManageK8s(ctx context.Context, lg *slog.Logger, c HTTPConfig, cd HTTPConfig, mx *muxRegister) error {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	bi, _ := debug.ReadBuildInfo()
	name := path.Base(bi.Path)
	lg.LogAttrs(ctx, slog.LevelDebug, "identified name", slog.String("name", name))

	namespaceBytes, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
	if err != nil {
		return fmt.Errorf("get current namespace: %w", err)
	}
	namespace := string(namespaceBytes)
	lg.LogAttrs(ctx, slog.LevelDebug, "identified namespace", slog.String("namespace", namespace))

	k8sConfig, err := rest.InClusterConfig()
	if err != nil {
		return fmt.Errorf("get k8s in cluster config: %w", err)
	}

	k8sClient, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		return fmt.Errorf("create k8s client")
	}

	labelSelector, httpPort, debugPort, err := getPodPorts(ctx, lg, k8sClient, namespace, c.Address, cd.Address)
	if err != nil {
		return err
	}

	manager := "yrun-" + name

	err = createService(ctx, lg, k8sClient, manager, namespace, name, httpPort, debugPort, labelSelector)
	if err != nil {
		return err
	}

	err = createHTTPRoute(ctx, lg, k8sConfig, manager,
		namespace, name,
		c.K8s.GatewayNamespace, c.K8s.GatewayName,
		mx.hosts,
		labelSelector)
	if err != nil {
		return err
	}
	return nil
}

func getPodPorts(ctx context.Context, lg *slog.Logger, k8sClient *kubernetes.Clientset, namespace, httpAddr, debugAddr string) (labels map[string]string, httpPort, debugPort string, err error) {
	podName, err := os.Hostname()
	if err != nil {
		return nil, "", "", fmt.Errorf("read hostname: %w", err)
	}
	lg.LogAttrs(ctx, slog.LevelDebug, "identified pod name from hostname", slog.String("pod.name", podName))

	pod, err := k8sClient.CoreV1().Pods(namespace).Get(ctx, podName, apimetav1.GetOptions{})
	if err != nil {
		return nil, "", "", fmt.Errorf("get pod: %w", err)
	}

	labelSelector := make(map[string]string)
	for k, v := range pod.Labels {
		switch k {
		case "app.kubernetes.io/name", "app.kubernetes.io/instance":
			labelSelector[k] = v
		}
	}
	if len(labelSelector) == 0 {
		return nil, "", "", fmt.Errorf("no known labels: %w", err)
	}
	lg.LogAttrs(ctx, slog.LevelDebug, "got selector labels", slog.Any("labels", labelSelector))

	httpPort, err = findPort(httpAddr, pod)
	if err != nil {
		return nil, "", "", fmt.Errorf("find http port: %w", err)
	}
	debugPort, err = findPort(debugAddr, pod)
	if err != nil {
		return nil, "", "", fmt.Errorf("find debug port: %w", err)
	}

	return labelSelector, httpPort, debugPort, nil
}

func findPort(addr string, pod *apicorev1.Pod) (portName string, err error) {
	_, portNumS, err := net.SplitHostPort(addr)
	if err != nil {
		return "", fmt.Errorf("bad host:port for http: %w", err)
	}
	portNumI, err := strconv.Atoi(portNumS)
	if err != nil {
		return "", fmt.Errorf("parse port number: %w", err)
	}
	portNum := int32(portNumI)

	for _, container := range pod.Spec.Containers {
		for _, port := range container.Ports {
			if port.ContainerPort == portNum {
				portName = port.Name
			}
		}
	}

	return portName, nil
}

func createService(ctx context.Context, lg *slog.Logger, k8sClient *kubernetes.Clientset, manager, namespace, name, httpPort, debugPort string, labelSelector map[string]string) error {
	labels := maps.Clone(labelSelector)
	labels["kubernetes.io/managed-by"] = manager

	applySvc := &applycorev1.ServiceApplyConfiguration{
		TypeMetaApplyConfiguration: applymetav1.TypeMetaApplyConfiguration{
			APIVersion: ptr("v1"),
			Kind:       ptr("Service"),
		},
		ObjectMetaApplyConfiguration: &applymetav1.ObjectMetaApplyConfiguration{
			Name:      &name,
			Namespace: &namespace,
			Labels:    labels,
		},
		Spec: &applycorev1.ServiceSpecApplyConfiguration{
			Ports: []applycorev1.ServicePortApplyConfiguration{
				{
					Name:        ptr("http"),
					Port:        ptr[int32](80),
					Protocol:    ptr(apicorev1.ProtocolTCP),
					AppProtocol: ptr("http"),
					TargetPort:  ptr(intstr.FromString(httpPort)),
				}, {
					Name:        ptr("debug"),
					Port:        ptr[int32](8081),
					Protocol:    ptr(apicorev1.ProtocolTCP),
					AppProtocol: ptr("http"),
					TargetPort:  ptr(intstr.FromString(debugPort)),
				},
			},
			Selector: labelSelector,
		},
	}

	lg.LogAttrs(ctx, slog.LevelDebug, "applying service")
	res, err := k8sClient.CoreV1().Services(namespace).Apply(ctx, applySvc, apimetav1.ApplyOptions{
		FieldManager: manager,
	})
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "failed apply", slog.String("err", err.Error()))
		return fmt.Errorf("apply service %s/%s: %w", namespace, name, err)
	}
	lg.LogAttrs(ctx, slog.LevelDebug, "applied service", slog.Any("service.config", res))
	return nil
}

func createHTTPRoute(ctx context.Context, lg *slog.Logger, k8sConfig *rest.Config, manager, namespace, name, gatewayNamespace, gatewayName string, hosts map[string]struct{}, labelSelector map[string]string) error {
	var hostnames []gwapiv1.Hostname
	for host := range hosts {
		if host != "" {
			hostnames = append(hostnames, gwapiv1.Hostname(host))
		}
	}
	slices.Sort(hostnames)

	labels := maps.Clone(labelSelector)
	labels["kubernetes.io/managed-by"] = manager

	applyConfig := &gwapplyv1.HTTPRouteApplyConfiguration{
		TypeMetaApplyConfiguration: applymetav1.TypeMetaApplyConfiguration{
			APIVersion: ptr("gateway.networking.k8s.io/v1"),
			Kind:       ptr("HTTPRoute"),
		},
		ObjectMetaApplyConfiguration: &applymetav1.ObjectMetaApplyConfiguration{
			Name:      &name,
			Namespace: &namespace,
			Labels:    labels,
		},
		Spec: &gwapplyv1.HTTPRouteSpecApplyConfiguration{
			CommonRouteSpecApplyConfiguration: gwapplyv1.CommonRouteSpecApplyConfiguration{
				ParentRefs: []gwapplyv1.ParentReferenceApplyConfiguration{{
					Namespace: ptr(gwapiv1.Namespace(gatewayNamespace)),
					Name:      ptr(gwapiv1.ObjectName(gatewayName)),
				}},
			},
			Hostnames: hostnames,
			Rules: []gwapplyv1.HTTPRouteRuleApplyConfiguration{{
				BackendRefs: []gwapplyv1.HTTPBackendRefApplyConfiguration{{
					BackendRefApplyConfiguration: gwapplyv1.BackendRefApplyConfiguration{
						BackendObjectReferenceApplyConfiguration: gwapplyv1.BackendObjectReferenceApplyConfiguration{
							Name: ptr(gwapiv1.ObjectName(name)),
							Port: ptr(gwapiv1.PortNumber(80)),
						},
					},
				}},
			}},
		},
	}

	gatewayClient, err := gwclientv1.NewForConfig(k8sConfig)
	if err != nil {
		return fmt.Errorf("get gateway client: %w", err)
	}
	lg.LogAttrs(ctx, slog.LevelDebug, "applying httproute")
	res, err := gatewayClient.HTTPRoutes(namespace).Apply(ctx, applyConfig, apimetav1.ApplyOptions{
		FieldManager: manager,
	})
	if err != nil {
		lg.LogAttrs(ctx, slog.LevelError, "failed apply", slog.String("err", err.Error()))
		return fmt.Errorf("apply httproute %s/%s: %w", namespace, name, err)
	}
	lg.LogAttrs(ctx, slog.LevelDebug, "applied httproute", slog.Any("httproute.config", res))
	return nil
}
