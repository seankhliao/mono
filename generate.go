package main

//go:generate go tool buf generate

//go:generate go tool cue get go k8s.io/api/admissionregistration/v1
//go:generate go tool cue get go k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1
//go:generate go tool cue get go k8s.io/api/apps/v1
//go:generate go tool cue get go k8s.io/api/autoscaling/v2
//go:generate go tool cue get go k8s.io/api/batch/v1
//go:generate go tool cue get go github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1
//go:generate go tool cue get go k8s.io/api/core/v1
//go:generate go tool cue get go sigs.k8s.io/gateway-api/apis/v1
//go:generate go tool cue get go sigs.k8s.io/gateway-api/apis/v1alpha2
//go:generate go tool cue get go sigs.k8s.io/gateway-api/apis/v1beta1
//go:generate go tool cue get go k8s.io/api/networking/v1
//go:generate go tool cue get go k8s.io/api/policy/v1
//go:generate go tool cue get go k8s.io/api/rbac/v1
//go:generate go tool cue get go k8s.io/api/scheduling/v1
//go:generate go tool cue get go k8s.io/api/storage/v1
//go:generate go tool cue get go github.com/envoyproxy/gateway/api/v1alpha1
//go:generate go tool cue fix ./...
