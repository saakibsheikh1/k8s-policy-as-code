# Kubernetes Security & Policy-as-Code

## Kyverno Admission Control, Pod Security, Supply-Chain Policy and CI Guardrails

![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-blue)
![Kyverno](https://img.shields.io/badge/Kyverno-1.19.1-green)
![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Policy%20as%20Code](https://img.shields.io/badge/Policy--as--Code-Enabled-purple)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-black)

---

## 1. Project Overview

This project implements a Kubernetes security and policy-as-code framework on Amazon EKS using Kyverno.

The objective is to prevent insecure Kubernetes workloads from entering the cluster by enforcing security policies at admission time and validating manifests in CI before deployment.

The project implements controls for:

- Privileged container prevention
- Non-root container execution
- Linux capability restrictions
- CPU and memory resource requirements
- Image tag restrictions
- Required workload labels
- Approved container registry enforcement
- Audit-to-Enforce policy rollout
- Policy violation reporting
- Admission monitoring
- Rejection-spike alert demonstration
- CI policy validation
- Combined CI and Kubernetes admission guardrails
- Security research and operational runbook

---

# 2. Architecture

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
3. Technology Stack
Technology	Purpose
Amazon EKS	Managed Kubernetes cluster
Kyverno	Kubernetes-native policy engine
Kubernetes	Container orchestration
Amazon ECR	Approved container image registry
GitHub	Source control
GitHub Actions	CI policy validation
Kyverno CLI	Manifest policy validation
PowerShell	Local administration and testing
AWS CLI	AWS resource management
Helm	Kyverno installation and configuration
4. Environment

The implementation was performed using:

Cloud Provider: AWS
Kubernetes Platform: Amazon EKS
AWS Region: ap-south-1
Cluster: k8s-policy-as-code
Node Group: policy-workers
Node Instance Type: t3.small
Policy Engine: Kyverno v1.19.1

The cluster was created specifically for this security-policy laboratory project.

5. Repository Structure
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
6. Stage 1 — Admission Control
Objective

Install Kyverno on Amazon EKS and prevent privileged containers from being admitted into the cluster.

Implementation

Kyverno was installed using Helm.

The first admission policy prevents privileged containers:

policies/disallow-privileged.yaml

Policy behavior:

Privileged container
        |
        v
Kubernetes API Server
        |
        v
Kyverno
        |
        v
REJECT

A compliant workload is allowed:

Compliant workload
        |
        v
Kyverno
        |
        v
ALLOW
Test Results
Violating workload

A Pod containing:

securityContext:
  privileged: true

was rejected.

Expected rejection message:

Privileged containers are not allowed.
Compliant workload

A non-privileged workload was admitted successfully and subsequently removed after testing.

Result

Stage 1: COMPLETE

7. Stage 2 — Pod Security Policies

Stage 2 extends the admission control layer with multiple security policies.

7.1 Require Non-Root

File:

policies/require-non-root.yaml

Requirement:

securityContext:
  runAsNonRoot: true

Purpose:

Prevent containers from running as root
Reduce the impact of container compromise
Support least-privilege execution

A violating workload was rejected.

A compliant workload was admitted.

7.2 Drop Linux Capabilities

File:

policies/drop-capabilities.yaml

Requirement:

securityContext:
  capabilities:
    drop:
      - ALL

Purpose:

Reduce unnecessary Linux privileges
Minimize container attack surface

A violating workload was rejected.

A compliant workload was admitted.

7.3 Require CPU and Memory Resources

File:

policies/require-resources.yaml

Required fields:

resources:
  requests:
    cpu: ...
    memory: ...
  limits:
    cpu: ...
    memory: ...

Purpose:

Improve scheduling predictability
Prevent uncontrolled resource consumption
Improve resource isolation

A workload without the required resources was rejected.

A compliant workload was admitted.

7.4 Disallow latest Image Tag

File:

policies/disallow-latest-tag.yaml

Example prohibited image:

nginx:latest

Example accepted image:

nginx:1.27

Purpose:

Avoid mutable image references
Improve deployment reproducibility
Reduce ambiguity about which image version is deployed

A latest image was rejected.

A versioned image was admitted.

7.5 Require Workload Labels

File:

policies/require-labels.yaml

Required labels:

labels:
  app: ...
  environment: ...

Purpose:

Improve workload identification
Support operational management
Enable policy targeting
Improve resource organization

Workloads missing required labels were rejected.

Compliant workloads were admitted.

Stage 2 Result

The following controls were implemented and tested:

[✓] Require non-root
[✓] Drop dangerous capabilities
[✓] Require CPU/memory requests and limits
[✓] Disallow latest image tag
[✓] Require app label
[✓] Require environment label

Stage 2: COMPLETE

8. Stage 3 — Image and Supply-Chain Policy
Objective

Restrict workloads to images originating from an approved container registry.

Amazon ECR was selected as the approved registry for this project.

8.1 Approved ECR Repository

Repository:

k8s-policy-demo

Approved registry:

495278513365.dkr.ecr.ap-south-1.amazonaws.com/k8s-policy-demo

Policy:

policies/require-approved-registry.yaml
8.2 Public Registry Test

A public Docker Hub image was tested:

nginx:1.27

The image was rejected by Kyverno because it did not originate from the approved ECR registry.

Expected result:

Images must come from the approved ECR registry.
8.3 Approved ECR Image

The image was tagged and pushed to ECR:

495278513365.dkr.ecr.ap-south-1.amazonaws.com/k8s-policy-demo:1.27

The ECR image was successfully admitted when used by a compliant Pod.

8.4 ECR Scan-on-Push

ECR scan-on-push was enabled for the repository.

The project therefore provides:

Approved registry enforcement
        +
ECR image scanning configuration
Important Limitation

This project did not implement an admission rule that blocks an image based on:

Image signature verification
Vulnerability scan severity
Scan findings

Therefore, the project does not claim complete signature-based or vulnerability-result-based admission enforcement.

The demonstrated control is:

Unapproved registry
        |
        v
      DENY

and:

Approved ECR registry
        |
        v
      ALLOW

Stage 3: COMPLETE with documented supply-chain limitation

9. Stage 4 — Audit Before Enforce
Objective

Demonstrate how a new restrictive policy can be introduced in Audit mode before being converted to Enforce mode.

Policy:

policies/audit-host-network.yaml

The policy controls:

spec:
  hostNetwork: false
9.1 Audit Mode

The policy was initially configured with:

validationFailureAction: Audit

A workload using:

hostNetwork: true

was allowed to enter the cluster.

However, Kyverno recorded the violation in PolicyReports.

Example observation:

PASS: 8
FAIL: 1

This demonstrates the audit-before-enforce workflow.

9.2 Enforce Mode

The same policy was changed to:

validationFailureAction: Enforce

The violating workload was then rejected.

Expected message:

hostNetwork is not allowed for standard workloads.
9.3 Policy Exception

A scoped PolicyException manifest was created:

exceptions/host-network-exception.yaml

The intended exception scope was limited to:

Policy: audit-host-network
Rule: disallow-host-network
Namespace: default
Resource: host-network-exception
Exception Limitation

During testing, Kyverno reported:

The exceptionNamespace flag is not set

Therefore, this project does not claim that the PolicyException successfully bypassed the admission policy.

The limitation is intentionally documented rather than represented as a successful test.

Stage 4 Result
[✓] Audit mode demonstrated
[✓] PolicyReport violation observed
[✓] Policy changed to Enforce
[✓] Violating workload rejected
[✓] Scoped exception manifest created
[!] Exception namespace configuration remains a documented limitation

Stage 4: COMPLETE with documented exception limitation

10. Stage 5 — CI Policy Validation
Objective

Validate Kubernetes manifests before deployment using CI.

GitHub Actions workflow:

.github/workflows/policy-validation.yaml

Test manifests:

ci/test-manifests/violation.yaml
ci/test-manifests/compliant.yaml
10.1 Violating Manifest

The CI test contains multiple policy violations, including:

image: nginx:latest

and:

privileged: true

as well as missing resource configuration.

The CI workflow expects this manifest to fail policy validation.

10.2 Compliant Manifest

The compliant manifest uses:

runAsNonRoot: true
drop ALL capabilities
CPU requests and limits
Memory requests and limits
versioned ECR image
required labels
non-privileged container

The workflow expects this manifest to pass.

11. GitHub Actions Evidence

Workflow:

Kyverno Policy Validation

Commit:

57f9a46

Job:

Validate Kubernetes manifests

Result:

SUCCESS

The GitHub Actions workflow successfully executed the Kubernetes manifest policy validation.

The evidence screenshot is included in the project/report documentation.

12. Stage 5 — Admission Monitoring

Kyverno exposes metrics through:

kyverno-svc-metrics

Port:

8000

The metrics endpoint provides observability into Kyverno policy execution and admission activity.

The project uses the Kyverno metrics layer to support monitoring of:

Admission activity
Allowed requests
Rejected requests
Policy execution results
Policy violations
13. Rejection Spike Alert Demonstration

File:

ci/check-rejection-spike.ps1

The demonstration threshold is:

3 rejected requests
Alert Condition

Test:

Rejected requests: 3
Threshold: 3

Result:

ALERT: Kyverno admission rejection spike detected.
Normal Condition

Test:

Rejected requests: 1
Threshold: 3

Result:

OK: Rejection rate is below the alert threshold.

This demonstrates both:

Normal condition
       |
       v
      OK

and:

Rejection spike
       |
       v
     ALERT
Important Monitoring Limitation

The PowerShell script demonstrates the alert threshold logic. It does not itself collect historical metrics from Prometheus.

Kyverno's native metrics endpoint is available for integration with a production monitoring system such as Prometheus/Grafana.

14. Combined CI + Admission Guardrail

The project implements two independent security checkpoints.

Checkpoint 1 — CI
Developer
   |
   v
Pull Request
   |
   v
GitHub Actions
   |
   v
Kyverno Policy Validation
   |
   +---- violation ----> CI FAIL
   |
   +---- compliant ----> CI PASS
Checkpoint 2 — Cluster Admission
Deployment
   |
   v
Kubernetes API Server
   |
   v
Kyverno Admission Controller
   |
   +---- violation ----> REQUEST DENIED
   |
   +---- compliant ----> REQUEST ACCEPTED

This creates a defense-in-depth policy model.

Even if a policy violation reaches the deployment stage after passing through development tooling, Kubernetes admission control provides a second enforcement layer.

15. Security Controls Summary
Security Control	Implemented	Tested
Kyverno admission controller	Yes	Yes
Privileged container prevention	Yes	Yes
Require non-root	Yes	Yes
Drop all capabilities	Yes	Yes
Resource requests/limits	Yes	Yes
Disallow latest tag	Yes	Yes
Required labels	Yes	Yes
Approved ECR registry	Yes	Yes
Public image rejection	Yes	Yes
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
Runtime security enforcement	No	Outside admission scope
16. Pod Security Standards Mapping

The implemented policies provide controls that correspond to common Kubernetes Pod Security Standard requirements.

Examples include:

Privileged container prevention
        |
        v
Pod privilege restriction

runAsNonRoot
        |
        v
Non-root execution

Drop ALL capabilities
        |
        v
Linux capability restriction

Kubernetes Pod Security Admission provides the standardized:

Privileged
Baseline
Restricted

security levels.

This project uses Kyverno for custom policy-as-code enforcement while recognizing Kubernetes Pod Security Admission as a built-in security mechanism.

17. Policy-as-Code Principles

The project follows these principles:

Version Control

Policies are stored in Git:

policies/
Reviewable Changes

Policy changes are committed through Git and can be reviewed before deployment.

CI Validation

Kubernetes manifests are validated through:

.github/workflows/policy-validation.yaml
Admission Enforcement

Kyverno independently validates workloads at cluster admission.

Audit Before Enforcement

New restrictive policies can initially be introduced in Audit mode before moving to Enforce.

Scoped Exceptions

Exceptions are intended to be narrowly scoped rather than globally disabling security controls.

18. Operational Runbook

The operational runbook is available at:

docs/runbook.md

The runbook covers:

Identifying admission rejection
Finding the responsible Kyverno policy
Reviewing PolicyReports
Correcting workload configuration
Handling legitimate exceptions
Audit-before-enforce rollout
Policy-related deployment failures
Rollback and outage safety
Runtime security limitations
19. Security Research

The research document is available at:

docs/research.md

The research compares:

Kyverno
OPA Gatekeeper
Kubernetes Pod Security Admission

Comparison areas include:

Admission enforcement
Policy language
Custom policy capability
Audit functionality
CI integration
Exceptions
Kubernetes integration
Operational model

No performance ranking or benchmark claim is made because this project did not perform controlled benchmarks under identical conditions.

20. Runtime Security Limitation

Admission control is a preventive control.

It evaluates Kubernetes resources when they are created or updated.

It cannot guarantee that an already-admitted workload remains secure during runtime.

Examples of threats that policy-as-code alone cannot completely prevent:

Application vulnerability exploitation
Malicious code execution inside a permitted container
Credential theft after compromise
Unexpected outbound communication
Compromised dependencies
Runtime lateral movement

Additional runtime controls may include:

Vulnerability management
Runtime threat detection
Network policies
Least-privilege IAM
Container isolation
Monitoring
Alerting
Incident response
21. Client-Facing Security Statement

This platform enforces Kubernetes security requirements before and during deployment. CI policy validation detects non-compliant manifests before deployment, while Kyverno admission control independently blocks workloads that violate enforced policies. Registry restrictions reduce the risk of deploying images from unapproved sources. These controls provide strong preventive guardrails for configuration and admission-time risks, but they do not guarantee runtime security. An already-admitted workload can still contain exploitable application vulnerabilities or behave maliciously after deployment, so runtime monitoring, vulnerability management, network controls, least privilege, and incident response remain necessary.

22. AWS Resources

The temporary laboratory environment used:

EKS Cluster:
k8s-policy-as-code

Node Group:
policy-workers

ECR Repository:
k8s-policy-demo

AWS Region:
ap-south-1

The ECR repository was deleted after testing.

The EKS node group was subsequently scheduled for deletion before removing the EKS cluster.

23. Cleanup Procedure

After completing testing:

aws eks delete-nodegroup `
  --cluster-name k8s-policy-as-code `
  --nodegroup-name policy-workers `
  --region ap-south-1

Wait:

aws eks wait nodegroup-deleted `
  --cluster-name k8s-policy-as-code `
  --nodegroup-name policy-workers `
  --region ap-south-1

Then delete the cluster:

aws eks delete-cluster `
  --name k8s-policy-as-code `
  --region ap-south-1

Wait:

aws eks wait cluster-deleted `
  --name k8s-policy-as-code `
  --region ap-south-1

Verify:

aws eks describe-cluster `
  --name k8s-policy-as-code `
  --region ap-south-1

The expected final state is:

ResourceNotFoundException

ECR verification:

aws ecr describe-repositories `
  --repository-names k8s-policy-demo `
  --region ap-south-1

Expected:

RepositoryNotFoundException
24. Evidence

Evidence is maintained through:

docs/screenshots/

Important evidence includes:

Kyverno installation
Privileged workload rejection
Compliant workload admission
Stage 2 policy rejection tests
Public image rejection
Approved ECR image admission
Audit-mode PolicyReport
Enforce-mode rejection
GitHub Actions CI success
Monitoring/alert demonstration
AWS resource cleanup

Screenshots should not expose:

AWS account IDs
Access keys
Secret credentials
Passwords
Private tokens
Sensitive infrastructure information
25. Git History

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

All completed changes are maintained in the main branch.

26. Final Project Status
Completed
[✓] EKS security-policy environment
[✓] Kyverno installation
[✓] Privileged container admission control
[✓] Non-root enforcement
[✓] Capability restriction
[✓] Resource requirements
[✓] Latest image tag restriction
[✓] Required labels
[✓] Approved ECR registry
[✓] Public image rejection
[✓] ECR scan-on-push configuration
[✓] Audit mode
[✓] Enforce mode
[✓] PolicyReports
[✓] CI policy validation
[✓] GitHub Actions
[✓] Kyverno metrics exposure
[✓] Rejection-spike alert demonstration
[✓] Combined CI + admission guardrail
[✓] Security research
[✓] Operational runbook
[✓] Cluster security report
Documented Limitations
[!] Image signature admission blocking not implemented
[!] Vulnerability-scan-result admission blocking not implemented
[!] PolicyException runtime bypass not successfully exercised
[!] Alert script demonstrates threshold logic rather than Prometheus-based historical alerting
[!] Runtime security is outside admission-policy scope
Cleanup
[✓] ECR repository deleted
[~] EKS node group deletion in progress
[ ] EKS cluster deletion after node group removal
[ ] Final clean-account verification
27. Conclusion

This project demonstrates a defense-in-depth Kubernetes security model based on policy-as-code.

The security architecture combines:

Git
 |
 +--> Version-controlled policies
 |
 +--> CI validation
 |
 +--> Kubernetes admission control
 |
 +--> PolicyReports
 |
 +--> Metrics
 |
 +--> Alerting

The resulting security workflow is:

Write policy
     |
     v
Commit to Git
     |
     v
Validate through CI
     |
     v
Deploy workload
     |
     v
Kyverno admission control
     |
     +----------+
     |          |
     v          v
   ALLOW      DENY
     |          |
     v          v
 Workload    Violation

The implementation provides preventive controls for common Kubernetes configuration and supply-chain risks while clearly documenting areas that require additional runtime security controls.

Project Author

Sakib Sheikh

DevOps / Cloud Engineering Project

Technologies:

AWS
Amazon EKS
Kyverno
Kubernetes
Docker
Amazon ECR
Git
GitHub Actions
Policy-as-Code
CI/CD

**One correction from the earlier report:** keep the README's status as **“substantially complete / cleanup in progress”** until the `policy-workers` deletion finishes and the EKS cluster itself is deleted. That keeps the repository evidence accurate.
