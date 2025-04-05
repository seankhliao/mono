# kubecon eu day 3

## wrapping it all up

### _kubecon_ eu 2025 day 3

#### keynotes

##### [EU CRA](https://kccnceu2025.sched.com/event/1txCD/keynote-cutting-through-the-fog-clarifying-cra-compliance-in-cloud-native-eddie-knight-ospo-lead-sonatype-michael-lieberman-cto-kusari)

Open source projects are off the hook.
Individual contributors / maintainers are off the hook.
Companies are on the hook if open source relates to their line of business in any way.

#### talks

##### [Switching to ValidatingAdmissionPolicies](https://kccnceu2025.sched.com/event/1txFk/evaporating-kubernetes-security-risk-adopting-validating-admission-policy-at-scale-kaitlyn-lee-jordan-conard-datadog)

Compared to ValidatingWebhookConfiguration,
ValidatingAdmissionPolicies are lower cost, have a reduced surface area.
CEL is a decent language (compared to rego...).

Pass in parameters, or even custom CRDs by binding parameters.
Work across multiple controllers by storing a reference to a common sub-structure (podSpec).
Use `?.` and `.orValue()` for navigating unset values.
VAP is evaluated before VWC, so easy to audit / check.

CEL playground is a useful tool.

#### hallway

##### OpenTelemetry maintainers (Go)

Chat on challenges with Go dependencies.
Unlikely to change in the foreseeable future.

[otel weaver](https://github.com/open-telemetry/weaver) is a cool thing.

Chat on maintainer / approver pipeline,
How to get engagement outside of vendors.
