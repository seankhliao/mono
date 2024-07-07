package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"strings"

	apibatchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	clientbatchv1 "k8s.io/client-go/kubernetes/typed/batch/v1"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	if len(os.Args) < 3 {
		slog.Error("missing required args")
		os.Exit(1)
	}

	for idx, url := range os.Args[2:] {
		err := run(fmt.Sprintf("%s-%d", os.Args[1], idx), url)
		if err != nil {
			slog.Error("run", "err", err)
			os.Exit(1)
		}
	}
}

func run(jobName, magnetURL string) error {
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

	created, err := jobsClient.Create(ctx, &apibatchv1.Job{
		TypeMeta: metav1.TypeMeta{
			Kind:       "Job",
			APIVersion: "batch/v1",
		},
		ObjectMeta: metav1.ObjectMeta{
			Namespace: "default",
			Name:      fmt.Sprintf("aria-%s", strings.ReplaceAll(jobName, " ", "-")),
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
								"sh", "-c", fmt.Sprintf(`apk add aria2
cd /data
aria2c '%s'
                                                                `, magnetURL),
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
		return fmt.Errorf("create job: %w", err)
	}

	slog.Info("created job", "name", created.Name)
	return nil
}

func ptr[T any](v T) *T {
	return &v
}
