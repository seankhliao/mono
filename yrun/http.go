package yrun

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path"
	"runtime/debug"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/maragudk/gomponents"
	"github.com/maragudk/gomponents/html"
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

// HTTPConfig is the config for an http server
type HTTPConfig struct {
	// host:port listening address
	Address string

	K8s struct {
		Enable bool

		GatewayNamespace string
		GatewayName      string
	}
}

func debugMux() (reg HTTPRegistrar, getMux func() *http.ServeMux) {
	register := &debugRegister{
		mux: muxRegister{http.NewServeMux(), make(map[string]struct{})},
	}

	var finalize sync.Once
	getMux = func() *http.ServeMux {
		finalize.Do(func() {
			var links []gomponents.Node
			for _, link := range register.links {
				links = append(links, html.Li(html.A(html.Href(link), gomponents.Text(link))))
			}
			buf := new(bytes.Buffer)
			html.Doctype(
				html.HTML(
					html.Lang("en"),
					html.Head(
						html.Meta(html.Charset("utf-8")),
						html.Meta(html.Name("viewport"), html.Content("width=device-width,minimum-scale=1,initial-scale=1")),
						html.TitleEl(gomponents.Text("Debug Endpoints")),
					),
					html.Body(
						html.H1(gomponents.Text("Debug Endpoints")),
						html.Ul(links...),
					),
				),
			).Render(buf)
			index := buf.Bytes()
			t := time.Now()
			register.Pattern("GET", "", "/{$}", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if strings.Contains(r.Header.Get("accept"), "text/html") {
					http.ServeContent(w, r, "index.html", t, bytes.NewReader(index))
					return
				}
				for _, link := range register.links {
					u := &url.URL{}
					u.Scheme = "http"
					u.Host = r.Host
					u.Path = link
					fmt.Fprintf(w, "%s\n", u.String())
				}
			}))
		})
		return register.mux.mux
	}

	return register, getMux
}

type HTTPRegistrar interface {
	Handle(string, http.Handler)
	Pattern(method, host, pattern string, handler http.Handler)
}

type muxRegister struct {
	mux   *http.ServeMux
	hosts map[string]struct{}
}

func (r *muxRegister) Pattern(method, host, pattern string, handler http.Handler) {
	var pat strings.Builder
	if method != "" {
		pat.WriteString(method)
		pat.WriteString(" ")
	}
	pat.WriteString(host)
	if r.hosts == nil {
		r.hosts = make(map[string]struct{})
	}
	r.hosts[host] = struct{}{}
	pat.WriteString(pattern)
	r.mux.Handle(pat.String(), handler)
}

func (r *muxRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

type debugRegister struct {
	mux   muxRegister
	links []string
}

func (r *debugRegister) Pattern(method, host, pattern string, handler http.Handler) {
	r.mux.Pattern(method, host, pattern, handler)
	if !strings.Contains(pattern, "{") {
		r.links = append(r.links, pattern)
	}
}

func (r *debugRegister) Handle(s string, h http.Handler) {
	r.mux.Handle(s, h)
}

func ManageK8s(ctx context.Context, c HTTPConfig, mx *muxRegister) error {
	bi, _ := debug.ReadBuildInfo()
	name := path.Base(bi.Path)

	namespaceBytes, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
	if err != nil {
		return fmt.Errorf("get current namespace: %w", err)
	}
	namespace := string(namespaceBytes)

	k8sConfig, err := rest.InClusterConfig()
	if err != nil {
		return fmt.Errorf("get k8s in cluster config: %w", err)
	}

	k8sClient, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		return fmt.Errorf("create k8s client")
	}

	applySvc := &applycorev1.ServiceApplyConfiguration{
		ObjectMetaApplyConfiguration: &applymetav1.ObjectMetaApplyConfiguration{
			Name:      &name,
			Namespace: &namespace,
			Labels: map[string]string{
				"kubernetes.io/managed-by": path.Join("yrun", name),
			},
		},
		Spec: &applycorev1.ServiceSpecApplyConfiguration{
			Ports: []applycorev1.ServicePortApplyConfiguration{{
				Name:        ptr("http"),
				Port:        ptr[int32](80),
				Protocol:    ptr(apicorev1.Protocol("TCP")),
				AppProtocol: ptr("http"),
				TargetPort:  ptr(intstr.FromString("http")),
			}},
			Selector: map[string]string{
				"app.kubernetes.io/name": name,
			},
		},
	}

	_, err = k8sClient.CoreV1().Services(namespace).Apply(ctx, applySvc, apimetav1.ApplyOptions{
		FieldManager: "yrun",
	})
	if err != nil {
		return fmt.Errorf("apply service %s/%s: %w", namespace, name, err)
	}

	var hostnames []gwapiv1.Hostname
	for host := range mx.hosts {
		hostnames = append(hostnames, gwapiv1.Hostname(host))
	}
	slices.Sort(hostnames)

	gwNamespace := gwapiv1.Namespace(c.K8s.GatewayNamespace)
	gwName := gwapiv1.ObjectName(c.K8s.GatewayName)

	applyConfig := &gwapplyv1.HTTPRouteApplyConfiguration{
		ObjectMetaApplyConfiguration: &applymetav1.ObjectMetaApplyConfiguration{
			Name:      &name,
			Namespace: &namespace,
			Labels: map[string]string{
				"kubernetes.io/managed-by": path.Join("yrun", name),
			},
		},
		Spec: &gwapplyv1.HTTPRouteSpecApplyConfiguration{
			CommonRouteSpecApplyConfiguration: gwapplyv1.CommonRouteSpecApplyConfiguration{
				ParentRefs: []gwapplyv1.ParentReferenceApplyConfiguration{{
					Namespace: &gwNamespace,
					Name:      &gwName,
				}},
			},
			Hostnames: hostnames,
			Rules: []gwapplyv1.HTTPRouteRuleApplyConfiguration{{
				BackendRefs: []gwapplyv1.HTTPBackendRefApplyConfiguration{{
					BackendRefApplyConfiguration: gwapplyv1.BackendRefApplyConfiguration{
						BackendObjectReferenceApplyConfiguration: gwapplyv1.BackendObjectReferenceApplyConfiguration{
							Name: ptr(gwapiv1.ObjectName(*applySvc.Name)),
							Port: ptr(gwapiv1.PortNumber(*applySvc.Spec.Ports[0].Port)),
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
	_, err = gatewayClient.HTTPRoutes(namespace).Apply(ctx, applyConfig, apimetav1.ApplyOptions{
		FieldManager: "yrun",
	})
	if err != nil {
		return fmt.Errorf("apply httproute %s/%s: %w", namespace, name, err)
	}
	return nil
}

func ptr[T any](v T) *T {
	return &v
}
