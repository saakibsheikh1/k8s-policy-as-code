# Stage 5 — CI, Monitoring and Combined Guardrails

## CI Policy Validation

GitHub Actions workflow:
.github/workflows/policy-validation.yaml

The CI workflow validates Kubernetes manifests against the version-controlled Kyverno policies before deployment.

Test cases:

| Test | Expected result |
|---|---|
| ci/test-manifests/violation.yaml | Rejected |
| ci/test-manifests/compliant.yaml | Accepted |

GitHub Actions execution was successfully completed for commit 57f9a46.

## Admission Monitoring

Kyverno metrics are exposed through:

kyverno-svc-metrics on port 8000.

The cluster exposes Kyverno admission metrics for observing admission activity and policy results.

## Rejection Spike Alert

The repository contains:

ci/check-rejection-spike.ps1

The configured demonstration threshold is 3 rejected requests.

### Alert test

Input:

- Rejected requests: 3
- Threshold: 3

Result:

ALERT: Kyverno admission rejection spike detected.

### Normal-condition test

Input:

- Rejected requests: 1
- Threshold: 3

Result:

OK: Rejection rate is below the alert threshold.

This demonstrates the alert condition and normal condition separately.

## Combined CI + Admission Guardrail

The security model uses two enforcement layers:

1. CI validates Kubernetes manifests before deployment.
2. Kyverno admission control validates workloads when they enter the cluster.

Therefore, a manifest can be detected during CI and independently blocked by cluster admission control.

## Runtime Limitation

Admission policies cannot prevent every runtime attack after a workload has been admitted. Runtime behavior such as exploitation of an application vulnerability, malicious activity inside an already-running container, or attacks against a compromised workload requires runtime security controls, monitoring, least privilege, network controls, and appropriate incident response.

## Stage 5 Status

- CI validation: COMPLETE
- Admission metrics exposure: COMPLETE
- Rejection-spike alert logic: COMPLETE
- Alert trigger test: COMPLETE
- Normal-condition test: COMPLETE
- Combined CI + admission guardrail: COMPLETE
