@"
# Kubernetes Cluster Security Report

## Project

Kubernetes Security & Policy-as-Code

## Environment

- Kubernetes platform: Amazon EKS
- Region: ap-south-1
- Cluster: k8s-policy-as-code
- Policy engine: Kyverno
- Kyverno version used: v1.19.1
- Approved image registry: Amazon ECR

## Security Controls Implemented

### Stage 1 — Admission Control

Implemented:

- Kyverno admission controller
- Privileged container prevention
- Enforce mode
- Version-controlled policy

Evidence:

- Privileged test workload rejected.
- Compliant workload admitted.

Policy:

`policies/disallow-privileged.yaml`

## Stage 2 — Pod Security Policies

Implemented:

- Require non-root execution
- Drop all Linux capabilities
- Require CPU and memory requests/limits
- Disallow `latest` image tags
- Require application and environment labels

Evidence:

Each implemented policy was tested with a violating workload and a compliant workload.

Policies:

- `policies/require-non-root.yaml`
- `policies/drop-capabilities.yaml`
- `policies/require-resources.yaml`
- `policies/disallow-latest-tag.yaml`
- `policies/require-labels.yaml`

These controls align with common Pod Security requirements. Kubernetes Pod Security Admission provides the standardized privileged, baseline, and restricted levels.

Source:
https://kubernetes.io/docs/concepts/security/pod-security-admission/

## Stage 3 — Supply Chain Controls

Implemented:

- Approved Amazon ECR registry requirement
- Public Docker Hub image rejection
- Approved ECR image admission
- ECR scan-on-push enabled

Policy:

`policies/require-approved-registry.yaml`

ECR repository:

`k8s-policy-demo`

Important limitation:

This project did not implement admission-time blocking based on image signature verification or vulnerability scan findings. ECR scanning was enabled, but no scan result was used as an admission condition. Therefore the project claims registry restriction and scan-on-push configuration, not complete signature/scanning admission enforcement.

## Stage 4 — Audit and Enforcement

Implemented:

- Audit-mode policy testing
- PolicyReport observation
- Conversion from Audit to Enforce
- Rejection after enforcement

Policy:

`policies/audit-host-network.yaml`

The audit test demonstrated that a hostNetwork workload could initially be admitted while the violation was recorded. After changing the policy to Enforce, the equivalent violating workload was rejected.

### Policy Exception

A scoped PolicyException manifest was created for demonstration.

The Kyverno installation reported:

`The exceptionNamespace flag is not set`

Therefore the project does not claim a successful runtime exception bypass.

Current Kyverno documentation states that PolicyExceptions require explicit enablement and namespace configuration. The legacy PolicyException API used by this project is also deprecated in Kyverno 1.19.

Source:
https://kyverno.io/docs/guides/exceptions/

## Stage 5 — CI and Monitoring

### CI

GitHub Actions workflow:

`.github/workflows/policy-validation.yaml`

The workflow tests:

- violating manifest → expected rejection
- compliant manifest → expected acceptance

The workflow completed successfully for commit `57f9a46`.

Kyverno CLI supports applying policies to Kubernetes manifests in CI/CD pipelines.

Source:
https://kyverno.io/docs/subprojects/kyverno-cli/

### Monitoring

Kyverno metrics service:

`kyverno-svc-metrics`

Port:

`8000`

Kyverno exposes metrics covering policy execution and admission-related results.

Source:
https://kyverno.io/docs/reference/metrics/

### Rejection Alert Demonstration

Alert script:

`ci/check-rejection-spike.ps1`

Test 1:

- rejected requests: 3
- threshold: 3
- result: ALERT

Test 2:

- rejected requests: 1
- threshold: 3
- result: OK

This demonstrates the repository's rejection-spike alert logic.

## Combined Guardrail

The completed design uses two independent enforcement points:

Developer/PR
→ GitHub Actions
→ Kyverno policy validation
→ deployment

and:

Deployment
→ Kubernetes API
→ Kyverno admission
→ allow/reject

This reduces the chance that a policy violation reaches the cluster and provides a second enforcement layer at admission time.

## Security Research

Kyverno provides Kubernetes-native policy management and CI validation.

OPA Gatekeeper provides admission validation using the OPA Constraint Framework.

Kubernetes Pod Security Admission provides built-in enforcement of standardized Pod Security Standards.

Sources:

https://kyverno.io/docs/guides/applying-policies/

https://open-policy-agent.github.io/gatekeeper/website/docs/howto/

https://kubernetes.io/docs/concepts/security/pod-security-admission/

## Client-Facing Security Statement

This platform enforces Kubernetes security requirements before and during deployment. CI policy validation detects non-compliant manifests before they are deployed, while Kyverno admission control independently blocks workloads that violate enforced policies. Registry restrictions also reduce the risk of deploying images from unapproved sources. These controls provide strong preventive guardrails for configuration and admission-time risks, but they do not guarantee runtime security. An already-admitted workload can still contain exploitable application vulnerabilities or behave maliciously after deployment, so runtime monitoring, vulnerability management, network controls, least privilege, and incident response remain necessary.

## Runtime Security Gap

One important insecure pattern that admission policy alone cannot completely prevent is malicious behavior from an already-admitted workload.

Examples include:

- exploitation of an application vulnerability
- malicious code execution inside a permitted container
- credential theft after compromise
- unexpected outbound communication
- attacks against vulnerable dependencies

These require runtime and operational security controls in addition to admission policy.

## Final Status

Stage 1: Complete

Stage 2: Complete

Stage 3: Complete with documented limitation on signature/scan-based admission

Stage 4: Complete with documented PolicyException configuration limitation

Stage 5: Complete for CI validation, metrics exposure, rejection-alert demonstration, and combined guardrail design

Documentation: Complete

Final cleanup and evidence capture: Pending
"@ | Set-Content docs\cluster-security-report.md