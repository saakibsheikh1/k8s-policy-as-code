# Kubernetes Security & Policy-as-Code

## Kyverno Admission Control, Pod Security, Supply-Chain Policy and CI Guardrails

![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-blue)
![Kyverno](https://img.shields.io/badge/Kyverno-1.19.1-green)
![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Policy%20as%20Code](https://img.shields.io/badge/Policy--as--Code-Enabled-purple)
![GitHub%20Actions](https://img.shields.io/badge/CI-GitHub%20Actions-black)

---

# 1. Project Overview

This project implements a Kubernetes security and Policy-as-Code framework on Amazon EKS using Kyverno.

The primary objective is to prevent insecure Kubernetes workloads from entering the cluster by enforcing security policies at admission time and validating Kubernetes manifests in CI before deployment.

The project implements security controls for:

- Privileged container prevention
- Non-root container execution
- Linux capability restrictions
- CPU and memory resource requirements
- Image tag restrictions
- Required workload labels
- Approved container registry enforcement
- Audit-before-enforce policy rollout
- Policy violation reporting
- Admission monitoring
- Rejection-spike alert demonstration
- CI policy validation
- Combined CI and Kubernetes admission guardrails
- Security research
- Deployment troubleshooting runbook
- Runtime security limitations

---

# 2. Project Objectives

The project was designed around the following security objectives:

1. Install and configure a Kubernetes admission policy engine.
2. Prevent privileged workloads.
3. Enforce Pod security requirements.
4. Restrict container images to an approved registry.
5. Demonstrate audit-before-enforce deployment.
6. Demonstrate admission rejection of insecure workloads.
7. Validate policies through CI.
8. Monitor admission and policy activity.
9. Demonstrate rejection-spike alerting.
10. Document security architecture and operational procedures.
11. Clean up all temporary AWS resources after testing.

---

# 3. Architecture

```text
                         Developer
                             |
                             v
                    GitHub Pull Request
                             |
                             v
                  GitHub Actions CI
                             |
                             v
                    Kyverno CLI
                             |
                 +-----------+-----------+
                 |                       |
                 v                       v
          Compliant Manifest       Violating Manifest
                 |                       |
                 v                       v
               PASS                    FAIL
                 |
                 v
             Deployment
                 |
                 v
        Kubernetes API Server
                 |
                 v
       Kyverno Admission Control
                 |
          +------+------+
          |             |
          v             v
        ALLOW          DENY
          |             |
          v             v
       Workload     Policy Violation
                         |
                         v
                 Policy Reports
                         |
                         v
                  Kyverno Metrics
                         |
                         v
                  Alert / Monitoring
4. Security Model

The project uses two primary enforcement layers.

Layer 1 — CI
Developer
    |
    v
Pull Request
    |
    v
GitHub Actions
    |
    v
Kyverno CLI
    |
    +---- Violation ----> CI FAIL
    |
    +---- Compliant ----> CI PASS
Layer 2 — Kubernetes Admission
Deployment
    |
    v
Kubernetes API Server
    |
    v
Kyverno
    |
    +---- Violation ----> REQUEST DENIED
    |
    +---- Compliant ----> REQUEST ACCEPTED

This creates a defense-in-depth security model.

5. Technology Stack
Technology	Purpose
Amazon EKS	Managed Kubernetes platform
Kubernetes	Container orchestration
Kyverno	Kubernetes-native Policy-as-Code engine
Amazon ECR	Approved container image registry
GitHub	Source control
GitHub Actions	CI policy validation
Kyverno CLI	Kubernetes manifest policy validation
Helm	Kyverno installation
AWS CLI	AWS resource management
PowerShell	Local testing and administration
6. Environment

The project was implemented in the following environment:

Cloud Provider: AWS
Region: ap-south-1
Kubernetes Platform: Amazon EKS
Cluster: k8s-policy-as-code
Node Group: policy-workers
Node Instance Type: t3.small
Policy Engine: Kyverno v1.19.1
Approved Registry: Amazon ECR

The EKS cluster and node group were created specifically for this laboratory project.

After testing was completed, the EKS cluster, node group, and ECR repository were deleted.

7. Repository Structure
k8s-policy-as-code/
│
├── .github/
│   └── workflows/
│       └── policy-validation.yaml
│
├── ci/
│   ├── test-manifests/
│   │   ├── compliant.yaml
│   │   └── violation.yaml
│   │
│   └── check-rejection-spike.ps1
│
├── policies/
│   ├── disallow-privileged.yaml
│   ├── require-non-root.yaml
│   ├── drop-capabilities.yaml
│   ├── require-resources.yaml
│   ├── disallow-latest-tag.yaml
│   ├── require-labels.yaml
│   ├── require-approved-registry.yaml
│   └── audit-host-network.yaml
│
├── exceptions/
│   └── host-network-exception.yaml
│
├── docs/
│   ├── cluster-security-report.md
│   ├── research.md
│   ├── runbook.md
│   ├── stage5.md
│   └── screenshots/
│
└── README.md
8. Stage 1 — Admission Control
Objective

Install Kyverno on Amazon EKS and prevent privileged containers from being admitted into the cluster.

Policy
policies/disallow-privileged.yaml

The policy prevents containers from using:

securityContext:
  privileged: true
Admission Behavior
Privileged Pod
      |
      v
Kubernetes API Server
      |
      v
Kyverno
      |
      v
REJECT

A compliant workload follows:

Compliant Pod
      |
      v
Kubernetes API Server
      |
      v
Kyverno
      |
      v
ALLOW
Test

A Pod with:

securityContext:
  privileged: true

was submitted.

Result:

REJECTED

Expected policy message:

Privileged containers are not allowed.

A compliant workload was subsequently admitted successfully.

Result
Stage 1: COMPLETE
9. Stage 2 — Pod Security Policies

Stage 2 introduced multiple security controls.

9.1 Require Non-Root

File:

policies/require-non-root.yaml

Requirement:

securityContext:
  runAsNonRoot: true

Purpose:

Prevent containers from running as root.
Reduce the impact of container compromise.
Support least-privilege execution.

Test result:

Violation: REJECTED
Compliant workload: ADMITTED
10. Drop Dangerous Capabilities

File:

policies/drop-capabilities.yaml

Requirement:

securityContext:
  capabilities:
    drop:
      - ALL

Purpose:

Reduce Linux container privileges.
Minimize the attack surface of compromised containers.

Test result:

Violation: REJECTED
Compliant workload: ADMITTED
11. Require Resource Requests and Limits

File:

policies/require-resources.yaml

Required configuration:

resources:
  requests:
    cpu: ...
    memory: ...
  limits:
    cpu: ...
    memory: ...

Purpose:

Improve scheduling predictability.
Improve resource isolation.
Prevent uncontrolled resource consumption.

Test result:

Violation: REJECTED
Compliant workload: ADMITTED
12. Disallow latest Image Tag

File:

policies/disallow-latest-tag.yaml

Prohibited:

nginx:latest

Accepted example:

nginx:1.27

Purpose:

Avoid mutable image references.
Improve deployment reproducibility.
Make deployed image versions explicit.

Test result:

latest image: REJECTED
versioned image: ADMITTED
13. Require Workload Labels

File:

policies/require-labels.yaml

Required labels:

metadata:
  labels:
    app: example
    environment: production

Purpose:

Improve workload identification.
Improve resource management.
Support policy targeting.
Improve operational organization.

Test result:

Missing labels: REJECTED
Required labels: ADMITTED
14. Stage 2 Summary

Implemented security controls:

[✓] Require non-root
[✓] Drop all Linux capabilities
[✓] Require CPU requests
[✓] Require memory requests
[✓] Require CPU limits
[✓] Require memory limits
[✓] Disallow latest image tag
[✓] Require app label
[✓] Require environment label

Result:

Stage 2: COMPLETE
15. Stage 3 — Image and Supply-Chain Security
Objective

Restrict container images to an approved Amazon ECR repository.

Policy:

policies/require-approved-registry.yaml

Approved repository:

k8s-policy-demo

Approved image registry:

495278513365.dkr.ecr.ap-south-1.amazonaws.com/k8s-policy-demo
16. Public Registry Rejection

A public Docker Hub image was tested:

nginx:1.27

The image did not originate from the approved ECR repository.

Result:

REJECTED

Expected message:

Images must come from the approved ECR registry.
17. Approved ECR Image

The image was tagged and pushed to ECR:

495278513365.dkr.ecr.ap-south-1.amazonaws.com/k8s-policy-demo:1.27

A compliant Pod using the approved ECR image was admitted.

Result:

Approved ECR image: ADMITTED
18. ECR Image Scanning

ECR scan-on-push was enabled for:

k8s-policy-demo

This provides image scanning configuration at the registry level.

Important Limitation

The project did not implement an admission policy that blocks images based on:

Vulnerability scan severity
ECR scan findings
Image signature verification

Therefore, the project does not claim complete signature-based or vulnerability-result-based admission enforcement.

The demonstrated supply-chain control is:

Unapproved Registry
        |
        v
      DENY

and:

Approved ECR Registry
        |
        v
      ALLOW

Result:

Stage 3: COMPLETE
with documented scan/signature limitation
19. Stage 4 — Audit Before Enforce
Objective

Demonstrate a safe rollout approach where a new security rule is first evaluated in Audit mode before being switched to Enforce mode.

Policy:

policies/audit-host-network.yaml

The policy prevents standard workloads from using:

hostNetwork: true
20. Audit Mode

The policy was initially configured with:

validationFailureAction: Audit

A workload using:

hostNetwork: true

was allowed to enter the cluster.

The violation was recorded through Kyverno policy reporting.

This demonstrated:

New Policy
    |
    v
Audit Mode
    |
    v
Violation Reported
    |
    v
Workload Still Admitted
21. Enforce Mode

The policy was changed to:

validationFailureAction: Enforce

The same insecure workload configuration was tested again.

Result:

REJECTED

Expected message:

hostNetwork is not allowed for standard workloads.

This demonstrated:

Audit
  |
  v
Review violations
  |
  v
Remediate
  |
  v
Enforce
  |
  v
Reject violations
22. Policy Exception

A scoped PolicyException manifest was created:

exceptions/host-network-exception.yaml

The intended scope was limited to:

Policy:
audit-host-network

Rule:
disallow-host-network

Namespace:
default

Resource:
host-network-exception
Configuration Limitation

During testing Kyverno reported:

The exceptionNamespace flag is not set

Therefore, the project does not claim a successful runtime PolicyException bypass.

The exception configuration limitation was documented in the security report.

This is intentionally reported as a limitation instead of being represented as a successful test.

Result:

Stage 4: COMPLETE
with documented PolicyException limitation
23. Stage 5 — CI Policy Validation
Objective

Validate Kubernetes manifests against the security policies before deployment.

GitHub Actions workflow:

.github/workflows/policy-validation.yaml

Test manifests:

ci/test-manifests/violation.yaml
ci/test-manifests/compliant.yaml
24. CI Violating Manifest

The violating manifest contains security-policy violations including:

image: nginx:latest

and:

privileged: true

and missing required resource configuration.

The CI workflow expects the manifest to fail policy validation.

Expected behavior:

Violation
   |
   v
Kyverno CLI
   |
   v
CI FAIL
25. CI Compliant Manifest

The compliant manifest contains:

runAsNonRoot: true
drop ALL capabilities
CPU requests
CPU limits
Memory requests
Memory limits
versioned ECR image
required labels
non-privileged container

Expected behavior:

Compliant
   |
   v
Kyverno CLI
   |
   v
CI PASS
26. GitHub Actions Result

Workflow:

Kyverno Policy Validation

Commit:

57f9a46

Job:

Validate Kubernetes manifests

Result:

SUCCESS

The GitHub Actions workflow successfully executed the policy-validation job.

Evidence was captured and included in the project documentation.

27. Stage 5 — Admission Monitoring

Kyverno metrics were exposed through:

kyverno-svc-metrics

Port:

8000

The metrics layer provides visibility into Kyverno policy execution and admission activity.

Monitoring can be used to observe:

Admission activity
Allowed requests
Rejected requests
Policy execution results
Policy violations
28. Rejection Spike Alert

The project contains:

ci/check-rejection-spike.ps1

Configured demonstration threshold:

3 rejected requests
Alert Test

Input:

Rejected Requests: 3
Threshold: 3

Result:

ALERT: Kyverno admission rejection spike detected.
Normal Condition Test

Input:

Rejected Requests: 1
Threshold: 3

Result:

OK: Rejection rate is below the alert threshold.

This demonstrates both alert and normal conditions.

29. Monitoring Limitation

The PowerShell alert script demonstrates the rejection threshold logic.

It does not itself provide long-term metric storage or historical analysis.

Kyverno's metrics endpoint can be integrated with a production monitoring stack such as Prometheus and Grafana.

The project therefore claims:

[✓] Kyverno metrics exposure
[✓] Rejection monitoring capability
[✓] Alert threshold logic
[✓] Alert trigger demonstration

It does not claim:

[ ] Full Prometheus-based production alerting
30. Combined CI + Admission Guardrail

The completed design provides two independent checkpoints.

CI Check
Developer
    |
    v
GitHub Pull Request
    |
    v
GitHub Actions
    |
    v
Kyverno Policy Validation
    |
    +---- Violation ----> FAIL
    |
    +---- Compliant ----> PASS
Cluster Check
Deployment
    |
    v
Kubernetes API Server
    |
    v
Kyverno Admission Controller
    |
    +---- Violation ----> DENY
    |
    +---- Compliant ----> ALLOW

Therefore:

CI Guardrail
      +
Admission Guardrail
      =
Defense in Depth
31. Security Controls Summary
Security Control	Implemented	Tested
Kyverno admission controller	Yes	Yes
Privileged container prevention	Yes	Yes
Require non-root	Yes	Yes
Drop Linux capabilities	Yes	Yes
Resource requests	Yes	Yes
Resource limits	Yes	Yes
Disallow latest tag	Yes	Yes
Required app label	Yes	Yes
Required environment label	Yes	Yes
Approved ECR registry	Yes	Yes
Public registry rejection	Yes	Yes
ECR scan-on-push	Yes	Yes
Scan-result admission blocking	No	N/A
Image signature admission blocking	No	N/A
Audit mode	Yes	Yes
Enforce mode	Yes	Yes
PolicyReports	Yes	Yes
PolicyException manifest	Yes	Configuration limitation
CI validation	Yes	Yes
GitHub Actions	Yes	Yes
Kyverno metrics	Yes	Yes
Rejection alert logic	Yes	Yes
Runtime security	Outside scope	N/A
32. Pod Security Standards Mapping

The implemented policies provide controls corresponding to common Kubernetes Pod Security requirements.

Examples:

Privileged container prevention
        |
        v
Container privilege restriction
runAsNonRoot
        |
        v
Non-root execution
Drop ALL capabilities
        |
        v
Linux capability restriction

Kubernetes Pod Security Admission provides standardized security levels:

Privileged
Baseline
Restricted

Kyverno was used in this project to provide custom Policy-as-Code controls and admission enforcement.

33. Policy-as-Code Design

The project follows Policy-as-Code principles.

Version Controlled Policies

Policies are stored under:

policies/
Git-Based Changes

Security policy changes are committed to Git.

CI Validation

Manifests are validated through:

.github/workflows/policy-validation.yaml
Admission Enforcement

Kyverno independently validates resources at Kubernetes admission time.

Audit Before Enforcement

New policies can first be introduced in Audit mode.

Scoped Exceptions

Exceptions are intended to be narrowly scoped and documented.

34. Operational Runbook

The deployment troubleshooting runbook is located at:

docs/runbook.md

It covers:

Identifying admission rejection.
Finding the responsible Kyverno policy.
Reviewing PolicyReports.
Checking Kubernetes events.
Correcting workload configuration.
Handling legitimate exceptions.
Audit-before-enforce rollout.
Policy-related deployment failures.
Rollback and outage safety.
Runtime security limitations.
35. Security Research

The research document is:

docs/research.md

It compares:

Kyverno
OPA Gatekeeper
Kubernetes Pod Security Admission

Comparison areas include:

Admission enforcement
Policy language
Custom policy capability
Audit capability
CI integration
Exceptions
Kubernetes integration
Operational model

No performance ranking is claimed because controlled benchmarks were not performed under identical conditions.

36. Runtime Security Limitation

Admission control is a preventive security control.

It evaluates Kubernetes resources when they are created or updated.

It cannot guarantee that an already-admitted workload remains secure during runtime.

Examples include:

Application vulnerability exploitation
Malicious code execution
Credential theft
Unexpected outbound communication
Compromised dependencies
Runtime lateral movement

Additional runtime security controls may include:

Vulnerability management
Runtime threat detection
Network policies
Least-privilege IAM
Container isolation
Monitoring
Alerting
Incident response

Therefore:

Admission Security
        +
Runtime Security
        +
Operational Security
        =
Defense in Depth
37. Client-Facing Security Statement

This platform enforces Kubernetes security requirements before and during deployment. CI policy validation detects non-compliant manifests before deployment, while Kyverno admission control independently blocks workloads that violate enforced policies. Registry restrictions reduce the risk of deploying images from unapproved sources. These controls provide strong preventive guardrails for configuration and admission-time risks, but they do not guarantee runtime security. An already-admitted workload can still contain exploitable application vulnerabilities or behave maliciously after deployment, so runtime monitoring, vulnerability management, network controls, least privilege, and incident response remain necessary.

38. AWS Resource Cleanup

Temporary AWS resources used for this project included:

EKS Cluster:
k8s-policy-as-code

Node Group:
policy-workers

ECR Repository:
k8s-policy-demo

The cleanup process was completed after testing.

ECR

The ECR repository was deleted successfully.

Verification returned:

RepositoryNotFoundException
EKS Node Group

The managed node group:

policy-workers

was deleted before deleting the EKS cluster.

EKS Cluster

The EKS cluster:

k8s-policy-as-code

was then deleted.

Final verification returned:

ResourceNotFoundException

indicating that the cluster no longer existed.

39. Cleanup Architecture

The cleanup sequence was:

Running EKS Cluster
        |
        v
Delete Node Group
        |
        v
Node Group Deleted
        |
        v
Delete EKS Cluster
        |
        v
Cluster Deleted
        |
        v
Verify ResourceNotFound

ECR was separately removed after image testing.

40. Evidence

Evidence is maintained under:

docs/screenshots/

Evidence includes:

Kyverno installation
Privileged workload rejection
Compliant workload admission
Stage 2 policy testing
Public image rejection
Approved ECR image admission
Audit-mode PolicyReport
Enforce-mode rejection
GitHub Actions CI success
Monitoring/alert testing
AWS cleanup

The GitHub Actions success screenshot demonstrates:

Workflow:
Kyverno Policy Validation

Job:
Validate Kubernetes manifests

Commit:
57f9a46

Result:
Success
41. Documentation Delivered

The project contains:

docs/cluster-security-report.md

Detailed implementation and security status report.

docs/research.md

Kyverno vs OPA Gatekeeper vs Kubernetes PSA research.

docs/runbook.md

Operational troubleshooting and deployment-failure runbook.

docs/stage5.md

CI, monitoring, alerting and combined guardrail documentation.

42. Git Repository

Repository:

https://github.com/saakibsheikh1/k8s-policy-as-code

Primary branch:

main

Final repository state:

Branch: main
Remote: origin/main
Working tree: clean
43. Important Git Commits

Major implementation milestones include:

Stage 1
feat: add privileged container admission policy
Stage 3
feat: enforce approved ECR image registry
Stage 5 CI
57f9a46
feat: add CI policy validation
Stage 5 Documentation
feat: complete CI monitoring and admission alert controls
Documentation
docs: complete security research runbook and cluster report
44. Final Completion Matrix
Area	Status
EKS security environment	COMPLETE
Kyverno installation	COMPLETE
Admission control	COMPLETE
Privileged workload prevention	COMPLETE
Non-root enforcement	COMPLETE
Capability restriction	COMPLETE
Resource enforcement	COMPLETE
Image tag restriction	COMPLETE
Required labels	COMPLETE
Approved registry enforcement	COMPLETE
Public image rejection	COMPLETE
ECR scan-on-push configuration	COMPLETE
Audit mode	COMPLETE
Enforce mode	COMPLETE
PolicyReports	COMPLETE
PolicyException manifest	COMPLETE*
CI policy validation	COMPLETE
GitHub Actions	COMPLETE
Kyverno metrics	COMPLETE
Rejection-spike alert demonstration	COMPLETE
Combined CI + admission guardrail	COMPLETE
Research documentation	COMPLETE
Operational runbook	COMPLETE
Security report	COMPLETE
AWS cleanup	COMPLETE
Repository cleanup	COMPLETE

* PolicyException was created but its runtime bypass was not successfully exercised because the required exception namespace configuration was not set.

45. Known Limitations

The following limitations are intentionally documented.

1. Image Signature Verification

Image signature verification was not implemented as an admission requirement.

2. Vulnerability Scan Admission Blocking

ECR scan-on-push was enabled, but scan findings were not used to reject Kubernetes workloads.

3. PolicyException Configuration

A PolicyException object was created, but Kyverno reported:

The exceptionNamespace flag is not set

Therefore a successful exception bypass is not claimed.

4. Production Alerting

The rejection-spike PowerShell script demonstrates alert logic.

A complete production monitoring architecture would connect Kyverno metrics to a metrics backend and alerting system.

5. Runtime Security

Admission policies cannot completely protect already-running workloads from runtime exploitation or malicious behavior.

46. Final Security Model

The final security architecture can be summarized as:

                    Git Repository
                         |
                         v
                Version-Controlled
                     Policies
                         |
                         v
                GitHub Actions CI
                         |
              +----------+----------+
              |                     |
              v                     v
          Compliant             Violation
              |                     |
              v                     v
            PASS                   FAIL
              |
              v
         Kubernetes
              |
              v
          API Server
              |
              v
           Kyverno
              |
        +-----+-----+
        |           |
        v           v
      ALLOW        DENY
        |           |
        v           v
    Workload     Violation
        |           |
        v           v
    Runtime     Monitoring
                  |
                  v
                Alert
47. Final Result

The project demonstrates a Kubernetes security framework based on Policy-as-Code with:

✓ Preventive admission control
✓ Pod security controls
✓ Supply-chain registry restriction
✓ Audit-before-enforce rollout
✓ Policy reporting
✓ CI validation
✓ Admission monitoring
✓ Rejection alert demonstration
✓ Defense-in-depth guardrails
✓ Security documentation
✓ Operational runbook
✓ AWS resource cleanup

The implementation is designed to prevent common Kubernetes configuration and admission-time security problems while clearly identifying security areas that require additional runtime controls.

48. Project Author
Sakib Sheikh

DevOps / Cloud Engineering Project

Technologies:

AWS
Amazon EKS
Kubernetes
Kyverno
Amazon ECR
Docker
Git
GitHub Actions
Helm
Policy-as-Code
CI/CD
Cloud Security
Container Security
49. Final Status
========================================
 KUBERNETES SECURITY & POLICY-AS-CODE
========================================

Implementation        : COMPLETE
Documentation         : COMPLETE
CI Validation         : COMPLETE
Monitoring Demo       : COMPLETE
Alert Demonstration   : COMPLETE
AWS Cleanup           : COMPLETE
Git Repository        : CLEAN
Project Status        : COMPLETE
========================================

End of Project


This version is the one I recommend using as the **final README** because it records the project as complete while still transparently preserving the two genuine limitations instead of overstating them.
