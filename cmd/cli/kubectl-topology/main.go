package main

import (
	"cmp"
	"context"
	"fmt"
	"os"
	"os/signal"
	"slices"
	"strings"
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
		Use:          "kubectl-topology (pod|node) [flags]",
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

	var sortBy string
	outw := tabwriter.NewWriter(os.Stdout, 6, 4, 3, ' ', 0)

	pods := &cobra.Command{
		Use:     "pod [flags]",
		Aliases: []string{"pods"},
		Args:    cobra.NoArgs,
		Short:   "show the zone distribution of pods",
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

			var hdr []string
			if listOpts.Namespace == "" {
				hdr = append(hdr, "NAMESPACE")
			}
			hdr = append(hdr, "NAME", "STATUS", "ZONE", "NODE", "TYPE", "POOL")
			fmt.Println(outw, strings.Join(hdr, "\t"))

			if len(podList.Items) == 0 {
				return nil
			}

			nodeList := &corev1.NodeList{}
			err = kclient.List(ctx, nodeList, listOpts)
			if err != nil {
				return fmt.Errorf("list nodes: %w", err)
			}
			nodeMap := make(map[string]nodeRow)
			for _, node := range nodeList.Items {
				nodeMap[node.Name] = fromNode(node)
			}

			var list []podRow
			for _, pod := range podList.Items {
				list = append(list, fromPod(pod, nodeMap))
			}

			switch sortBy {
			case "name":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.name, b.name) })
			case "status":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.status, b.status) })
			case "zone":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.nodeRow.zone, b.nodeRow.zone) })
			case "nodename":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.nodeRow.name, b.nodeRow.name) })
			case "nodetype":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.nodeRow.ntype, b.nodeRow.ntype) })
			case "pool":
				slices.SortFunc(list, func(a, b podRow) int { return cmp.Compare(a.nodeRow.pool, b.nodeRow.pool) })
			}

			for _, row := range list {
				outrow := []string{}
				if listOpts.Namespace == "" {
					outrow = append(outrow, row.namespace)
				}

				outrow = append(outrow, row.name, row.status, row.nodeRow.zone, row.nodeRow.name, row.nodeRow.ntype, row.nodeRow.pool)
				fmt.Fprintln(outw, strings.Join(outrow, "\t"))
			}

			return outw.Flush()
		},
	}

	pods.Flags().StringVar(&sortBy, "sort-by", "", "sort by the given field: name|status|zone|nodename|nodetype|pool")

	nodes := &cobra.Command{
		Use:     "node [flags]",
		Aliases: []string{"nodes"},
		Args:    cobra.NoArgs,
		Short:   "show the zone distribution of nodes",
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

			var list []nodeRow
			for _, node := range nodeList.Items {
				list = append(list, fromNode(node))
			}

			switch sortBy {
			case "name":
				slices.SortFunc(list, func(a, b nodeRow) int { return cmp.Compare(a.name, b.name) })
			case "status":
				slices.SortFunc(list, func(a, b nodeRow) int { return cmp.Compare(a.status, b.status) })
			case "zone":
				slices.SortFunc(list, func(a, b nodeRow) int { return cmp.Compare(a.zone, b.zone) })
			case "nodetype":
				slices.SortFunc(list, func(a, b nodeRow) int { return cmp.Compare(a.ntype, b.ntype) })
			case "pool":
				slices.SortFunc(list, func(a, b nodeRow) int { return cmp.Compare(a.name, b.name) })
			}

			hdr := []string{"NAME", "STATUS", "ZONE", "TYPE", "POOL"}
			fmt.Fprintln(outw, strings.Join(hdr, "\t"))
			for _, row := range list {
				fmt.Fprintln(outw, strings.Join([]string{row.name, row.status, row.zone, row.ntype, row.pool}, "\t"))
			}

			return outw.Flush()
		},
	}

	nodes.Flags().StringVar(&sortBy, "sort-by", "", "sort by the given field: ")

	root.AddCommand(pods, nodes)
	return root
}

type podRow struct {
	namespace string
	name      string
	status    string
	nodeRow   nodeRow
}

func fromPod(pod corev1.Pod, nodes map[string]nodeRow) podRow {
	row := podRow{
		namespace: pod.Namespace,
		name:      pod.Name,
	}
	for _, cond := range pod.Status.Conditions {
		if cond.Type == corev1.PodReady {
			if cond.Status == corev1.ConditionTrue {
				row.status = string(corev1.PodReady)
			} else {
				row.status = cond.Reason
			}
			break
		}
	}
	row.nodeRow = nodes[pod.Spec.NodeName]
	return row
}

type nodeRow struct {
	name   string
	status string
	zone   string
	ntype  string
	pool   string
}

func fromNode(node corev1.Node) nodeRow {
	row := nodeRow{
		name:  node.Name,
		zone:  node.Labels[zoneLabel],
		ntype: node.Labels[nodeTypeLabel],
		pool:  cmp.Or(node.Labels[karpenterPoolLabel]),
	}
	for _, cond := range node.Status.Conditions {
		if cond.Type == corev1.NodeReady {
			if cond.Status == corev1.ConditionTrue {
				row.status = string(corev1.NodeReady)
			} else {
				row.status = cond.Reason
			}
			break
		}
	}
	return row
}
