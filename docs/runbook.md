@"
# Policy Deployment Failure Runbook

## Purpose

Use this runbook when a workload that previously deployed successfully starts failing after a new Kyverno policy is introduced.

## 1. Identify the rejection

Check the deployment or Pod event:

kubectl describe pod <pod-name> -n <namespace>

Also inspect recent events:

kubectl get events -n <namespace> --sort-by=.lastTimestamp

Look for a Kyverno policy name and rule name in the rejection message.

## 2. Identify the active policy

List Kyverno policies:

kubectl get clusterpolicies

Inspect the relevant policy:

kubectl describe clusterpolicy <policy-name>

Confirm whether the policy is configured for Enforce or Audit behavior.

## 3. Check PolicyReports

Run:

kubectl get policyreport -A

Inspect a specific report:

kubectl describe policyreport <report-name> -n <namespace>

Look for Failed results and identify the policy/rule responsible.

## 4. Determine whether the workload is genuinely non-compliant

Compare the workload against the policy.

Typical failures include:

- privileged containers
- missing runAsNonRoot
- dangerous capabilities
- missing resource requests/limits
- latest image tags
- unapproved image registries
- missing required labels
- prohibited host networking

Do not immediately disable the policy.

## 5. Correct the workload

Prefer fixing the workload so that it satisfies the security requirement.

Examples:

- Replace privileged mode with the minimum required privileges.
- Configure runAsNonRoot.
- Drop unnecessary capabilities.
- Add CPU and memory requests/limits.
- Use immutable/versioned image tags.
- Pull images from the approved registry.
- Add required workload labels.

## 6. If a legitimate exception is required

Use a narrowly scoped PolicyException only when the deviation is understood, justified, and documented.

The exception should identify:

- policy
- rule
- resource
- namespace
- reason
- owner
- expected duration where applicable

Kyverno documentation recommends narrow exception scope and governance through RBAC/GitOps/policy controls.

Source:
https://kyverno.io/docs/guides/exceptions/

## 7. Test before deployment

Use the CI policy-validation workflow:

`.github/workflows/policy-validation.yaml`

The repository contains both violating and compliant test manifests under:

`ci/test-manifests/`

A policy violation should fail CI before deployment.

## 8. Audit-before-enforce procedure

For a new restrictive policy:

1. Start in Audit mode.
2. Review PolicyReports for existing violations.
3. Identify legitimate workloads requiring remediation or documented exceptions.
4. Fix workloads.
5. Confirm remaining violations are understood.
6. Change the policy to Enforce.
7. Test both a violating and compliant workload.

## 9. Rollback / outage safety

If a new policy causes an unexpected production deployment failure:

1. Identify the exact policy and rule.
2. Stop further rollout if necessary.
3. Determine whether the workload is actually violating the intended security requirement.
4. Prefer correcting the workload.
5. If the policy itself is incorrectly scoped, temporarily move the policy to Audit or correct the policy definition through the normal Git workflow.
6. Record the incident and affected workload.
7. Re-enable enforcement after validation.

Avoid deleting Kyverno or globally disabling admission control as the first response.

## 10. Runtime limitation

Admission control evaluates resources when they are submitted or updated. It cannot guarantee that an already-admitted workload will remain secure during runtime.

Runtime threats require additional controls such as:

- vulnerability management
- runtime detection
- network policies
- least-privilege IAM
- container isolation
- monitoring and alerting
- incident response

## Quick Commands

kubectl get clusterpolicies

kubectl get policyreport -A

kubectl describe policyreport <name> -n <namespace>

kubectl get events -A --sort-by=.lastTimestamp

kubectl describe pod <name> -n <namespace>
"@ | Set-Content docs\runbook.md