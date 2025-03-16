# validating admission policy in EKS

## CEL in K8s

### _Validating_ Admission Policy

K8s 1.30 gains [Validating Admission Policy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/),
like `ValidatingWebhookConfiguration`,
but built in using [CEL](https://github.com/google/cel-spec) 
and without the need to run your own server.

You might wonder if you can use it in EKS,
and you'll find [this re:Post](https://repost.aws/questions/QUkJXUbTxvR_-XnCwWQRznjA/validating-admission-policy-support-for-eks).
It's wrong.
ValidatingAdmissionPolicy is available in EKS 1.30.
