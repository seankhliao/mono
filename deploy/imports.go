package deploy

import (
	_ "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
	_ "github.com/envoyproxy/gateway/api/v1alpha1"
	_ "k8s.io/api/admissionregistration/v1"
	_ "k8s.io/api/apps/v1"
	_ "k8s.io/api/autoscaling/v2"
	_ "k8s.io/api/batch/v1"
	_ "k8s.io/api/core/v1"
	_ "k8s.io/api/networking/v1"
	_ "k8s.io/api/policy/v1"
	_ "k8s.io/api/rbac/v1"
	_ "k8s.io/api/scheduling/v1"
	_ "k8s.io/api/storage/v1"
	_ "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	_ "sigs.k8s.io/gateway-api/apis/v1"
	_ "sigs.k8s.io/gateway-api/apis/v1alpha2"
	_ "sigs.k8s.io/gateway-api/apis/v1beta1"
)
