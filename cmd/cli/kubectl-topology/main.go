package main

import (
	"cmp"
	"context"
	"fmt"
	"os"
	"os/signal"
	"text/tabwriter"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/cli-runtime/pkg/genericclioptions"
	"k8s.io/client-go/tools/clientcmd"

	"sigs.k8s.io/controller-runtime/pkg/client"
)

const (
	zoneLabel          = "topology.kubernetes.io/zone"
	nodeTypeLabel      = "node.kubernetes.io/instance-type"
	karpenterPoolLabel = "karpenter.sh/nodepool"
)

func main() {
	root := setup()

	err := root.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func setup() *cobra.Command {
	pflag.CommandLine = pflag.NewFlagSet("kubectl-topology", pflag.ExitOnError)

	var kclient client.Client
	kconfig := genericclioptions.NewConfigFlags(true)
	lconfig := genericclioptions.NewResourceBuilderFlags()
	lconfig = lconfig.WithAllNamespaces(false)
	lconfig = lconfig.WithLabelSelector("")

	loaodingRules := clientcmd.NewDefaultClientConfigLoadingRules()
	kubeConf := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(loaodingRules, nil)
	defaultNS, _, err := kubeConf.Namespace()
	if err == nil {
		kconfig.Namespace = &defaultNS
	}

	root := &cobra.Command{
		Use:          "kubectl-topology",
		Args:         cobra.NoArgs,
		SilenceUsage: true,
		Short:        "show the zones pods/nodes are deployed to",
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			kconf, err := kconfig.ToRESTConfig()
			if err != nil {
				return fmt.Errorf("generate k8s config: %w", err)
			}
			kclient, err = client.New(kconf, client.Options{})
			if err != nil {
				return fmt.Errorf("create k8s client: %w", err)
			}
			return nil
		},
	}
	kconfig.AddFlags(root.PersistentFlags())
	lconfig.AddFlags(root.PersistentFlags())

	ctx := context.Background()
	ctx, _ = signal.NotifyContext(ctx, os.Interrupt)

	outw := tabwriter.NewWriter(os.Stdout, 6, 4, 3, ' ', 0)

	pods := &cobra.Command{
		Use:     "pod [flags]",
		Aliases: []string{"pods"},
		RunE: func(cmd *cobra.Command, args []string) error {
			podList := &corev1.PodList{}
			listOpts := &client.ListOptions{}
			if kconfig.Namespace != nil {
				listOpts.Namespace = *kconfig.Namespace
			}
			if lconfig.AllNamespaces != nil && *lconfig.AllNamespaces {
				listOpts.Namespace = ""
			}

			if lconfig.FieldSelector != nil && *lconfig.FieldSelector != "" {
				sel, err := labels.Parse(*lconfig.FieldSelector)
				if err != nil {
					return fmt.Errorf("parse label selector: %w", err)
				}
				listOpts.LabelSelector = sel
			}

			err := kclient.List(ctx, podList, listOpts)
			if err != nil {
				return fmt.Errorf("list pods: %w", err)
			}

			const tmpl = "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n"
			fmt.Fprintf(outw, tmpl, "NAMESPACE", "NAME", "STATUS", "ADDRESS", "NODE", "ZONE", "TYPE", "POOL")

			if len(podList.Items) == 0 {
				return nil
			}

			nodeList := &corev1.NodeList{}
			err = kclient.List(ctx, nodeList, listOpts)
			if err != nil {
				return fmt.Errorf("list nodes: %w", err)
			}
			nodeMap := make(map[string]corev1.Node)
			for _, node := range nodeList.Items {
				nodeMap[node.Name] = node
			}

			for _, pod := range podList.Items {
				status := ""
				for _, cond := range pod.Status.Conditions {
					if cond.Type == corev1.PodReady {
						if cond.Status == corev1.ConditionTrue {
							status = string(corev1.PodReady)
						} else {
							status = cond.Reason
						}
						break
					}
				}

				var zone string
				node, ok := nodeMap[pod.Spec.NodeName]
				if ok {
					zone = node.Labels[zoneLabel]
				}

				fmt.Fprintf(outw, tmpl, pod.Namespace, pod.Name, status, pod.Status.PodIP, pod.Spec.NodeName, zone, node.Labels[nodeTypeLabel], cmp.Or(node.Labels[karpenterPoolLabel]))
			}

			return outw.Flush()
		},
	}

	nodes := &cobra.Command{
		Use:     "node [flags]",
		Aliases: []string{"nodes"},
		RunE: func(cmd *cobra.Command, args []string) error {
			listOpts := &client.ListOptions{}
			if lconfig.FieldSelector != nil && *lconfig.FieldSelector != "" {
				sel, err := labels.Parse(*lconfig.FieldSelector)
				if err != nil {
					return fmt.Errorf("parse label selector: %w", err)
				}
				listOpts.LabelSelector = sel
			}

			nodeList := &corev1.NodeList{}
			err := kclient.List(ctx, nodeList, listOpts)
			if err != nil {
				return fmt.Errorf("list nodes: %w", err)
			}

			const tmpl = "%s\t%s\t%s\t%s\t%s\t%s\n"
			fmt.Fprintf(outw, tmpl, "NAME", "STATUS", "ADDRESS", "ZONE", "TYPE", "POOL")
			for _, node := range nodeList.Items {
				status := ""
				for _, cond := range node.Status.Conditions {
					if cond.Type == corev1.NodeReady {
						if cond.Status == corev1.ConditionTrue {
							status = string(corev1.NodeReady)
						} else {
							status = cond.Reason
						}
						break
					}
				}
				addr := ""
				if len(node.Status.Addresses) > 0 {
					addr = node.Status.Addresses[0].Address
				}
				fmt.Fprintf(outw, tmpl, node.Name, status, addr, node.Labels[zoneLabel], node.Labels[nodeTypeLabel], cmp.Or(node.Labels[karpenterPoolLabel]))
			}

			return outw.Flush()
		},
	}

	root.AddCommand(pods, nodes)
	return root
}
