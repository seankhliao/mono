package main

import (
	"bufio"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"strings"

	apibatchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	clientbatchv1 "k8s.io/client-go/kubernetes/typed/batch/v1"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	var input io.Reader
	switch len(os.Args) {
	case 1:
		input = os.Stdin
	case 2:
		f, err := os.Open(os.Args[1])
		if err != nil {
			fmt.Fprintln(os.Stderr, "open file", os.Args[1], err)
			os.Exit(1)
		}
		input = f
	case 3:
		fmt.Fprintln(os.Stderr, "unexpected args", os.Args[2:])
		os.Exit(1)
	default:
		fmt.Fprintln(os.Stderr, "no args??")
		os.Exit(2)
	}

	err := run(input)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(r io.Reader) error {
	loadingRules := clientcmd.NewDefaultClientConfigLoadingRules()
	configOverrides := &clientcmd.ConfigOverrides{}
	kubeConfig := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(loadingRules, configOverrides)
	config, err := kubeConfig.ClientConfig()
	if err != nil {
		return fmt.Errorf("get kubeconfig: %w", err)
	}

	batchClient, err := clientbatchv1.NewForConfig(config)
	if err != nil {
		return fmt.Errorf("create batch client: %w", err)
	}
	jobsClient := batchClient.Jobs("default")

	ctx := context.Background()

	sc := bufio.NewScanner(r)
	for i := 0; sc.Scan(); i++ {
		link := sc.Text()
		if !strings.HasPrefix(link, "magnet") {
			return fmt.Errorf("[%d] expected magnet link, got %q", i, link)
		}

		name, err := createJob(ctx, jobsClient, link)
		if err != nil {
			return fmt.Errorf("[%d] create job: %w", i, err)
		}
		fmt.Println("created job -n default", name)
	}
	return nil
}

func createJob(ctx context.Context, client clientbatchv1.JobInterface, link string) (string, error) {
	linkHash := sha256.Sum256([]byte(link))
	name := hex.EncodeToString(linkHash[:])
	name = "aria-dl-" + name[:8]
	created, err := client.Create(ctx, &apibatchv1.Job{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Job",
			APIVersion: "batch/v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Namespace: "default",
			Name:      name,
		},
		Spec: apibatchv1.JobSpec{
			BackoffLimit:            ptr[int32](3),
			TTLSecondsAfterFinished: ptr[int32](60 * 60 * 3),
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					RestartPolicy: corev1.RestartPolicyOnFailure,
					Containers: []corev1.Container{
						{
							Name:  "aria",
							Image: "docker.io/library/alpine:latest",
							Command: []string{
								"sh", "-c", fmt.Sprintf(`apk add aria2 && cd /data && aria2c '%s'`, link),
							},
							VolumeMounts: []corev1.VolumeMount{
								{
									Name:      "data",
									MountPath: "/data",
								},
							},
						},
					},
					Volumes: []corev1.Volume{
						{
							Name: "data",
							VolumeSource: corev1.VolumeSource{
								HostPath: &corev1.HostPathVolumeSource{
									Path: "/opt/volumes/aria",
								},
							},
						},
					},
				},
			},
		},
	}, metav1.CreateOptions{})
	if err != nil {
		return "", fmt.Errorf("create job: %w", err)
	}
	return created.Name, nil
}

func ptr[T any](v T) *T {
	return &v
}
