@"
# Policy-as-Code Research

## Kyverno vs OPA Gatekeeper vs Kubernetes Pod Security Admission

| Capability | Kyverno | OPA Gatekeeper | Kubernetes PSA |
|---|---|---|---|
| Admission enforcement | Yes | Yes | Yes |
| Policy language | Kubernetes-native YAML/patterns and CEL-based policies | Rego/CEL through Constraint Framework | Predefined Pod Security Standards |
| Custom application policies | Broad Kubernetes resource validation/mutation capabilities | Broad policy framework using constraints | Focused on Pod Security Standards |
| Audit capability | Policy Reports and audit/background processing | Audit mode reports violations | Built-in audit mode |
| CI validation | Kyverno CLI supports manifest validation | Gatekeeper has policy testing/tooling | Primarily cluster admission control |
| Exceptions | PolicyException resources with scoped matching | Constraint exclusions / exemptions | Explicit PSA exemptions |
| Ease for Kubernetes YAML users | High | Requires understanding Constraint/Template model and Rego/CEL | Very simple for standard Pod Security |
| Best fit in this project | Main policy engine | Alternative policy engine | Baseline pod-security layer |

### Kyverno

Kyverno is a Kubernetes-native policy engine. It can receive admission requests from the Kubernetes API server, evaluate matching policies, and enforce or reject requests. Kyverno also provides a CLI that can evaluate Kubernetes manifests in CI/CD pipelines before deployment.

Source:
https://kyverno.io/docs/guides/applying-policies/

Source:
https://kyverno.io/docs/subprojects/kyverno-cli/

### OPA Gatekeeper

Gatekeeper uses the Open Policy Agent Constraint Framework. Validation policies use ConstraintTemplate and Constraint resources, with policy logic implemented using Rego or CEL. Gatekeeper supports admission validation and audit-style violation reporting.

Source:
https://open-policy-agent.github.io/gatekeeper/website/docs/howto/

Source:
https://open-policy-agent.github.io/gatekeeper/website/docs/constrainttemplates/

### Kubernetes Pod Security Admission

Pod Security Admission is built into Kubernetes and enforces the Pod Security Standards. The standards define the privileged, baseline, and restricted levels. PSA supports enforce, audit, and warn modes through namespace labels.

Source:
https://kubernetes.io/docs/concepts/security/pod-security-admission/

### Admission Flow

The simplified admission flow used by this project is:

1. A user or CI/CD system submits a Kubernetes resource.
2. The Kubernetes API server processes the request.
3. Admission controllers/webhooks evaluate the request.
4. Kyverno evaluates matching policies.
5. A compliant request is admitted.
6. A violating request in Enforce mode is rejected.
7. Policy results can be reported and exposed through Kyverno metrics.

Kyverno operates as a dynamic admission controller and can also evaluate manifests through its CLI before they reach the cluster.

Source:
https://kyverno.io/docs/guides/applying-policies/

### Validating vs Mutating Admission

Validating admission determines whether a resource satisfies policy requirements and can reject an invalid request.

Mutating admission changes a resource before it is persisted, when a configured mutating policy applies.

This project primarily uses validation policies because the objective is to demonstrate explicit rejection of insecure workloads.

### Policy Exceptions

Kyverno supports scoped PolicyException resources so that a specific resource can bypass a specific policy/rule without weakening the policy globally.

Current Kyverno documentation states that the legacy `kyverno.io/v2` PolicyException API is deprecated in Kyverno 1.19 and that the current API is `policies.kyverno.io/v1` for CEL-based policies. PolicyExceptions must also be explicitly enabled and scoped to permitted namespaces.

Source:
https://kyverno.io/docs/guides/exceptions/

Project note:

A legacy PolicyException object was created during this lab, but the cluster reported that the `exceptionNamespace` flag was not configured. Therefore this project does not claim a successfully exercised runtime exception. The limitation is documented rather than hidden.

### Summary

For this implementation, Kyverno was selected because it provides Kubernetes-native policy definitions, admission enforcement, PolicyReports, metrics, and a CLI suitable for CI validation.

PSA remains useful as a built-in Kubernetes security layer for standardized Pod Security Standards. Gatekeeper is a valid alternative when an organization prefers the OPA Constraint Framework and Rego/CEL policy model.

No benchmark or performance ranking is claimed because this project did not run controlled benchmarks under identical conditions.
"@ | Set-Content docs\research.md