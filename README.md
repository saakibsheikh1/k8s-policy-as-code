# Kubernetes Security & Policy-as-Code

## Project Overview

This project implements a Kubernetes Security and Policy-as-Code platform on Amazon EKS using Kyverno.

The objective is to harden the Kubernetes cluster by enforcing security and governance rules automatically at admission time. Insecure or non-compliant workloads should be rejected before they are allowed to run.

The project covers:

- Kubernetes admission control
- Kyverno policy engine
- Pod Security Standards
- Workload security policies
- Image provenance and supply-chain controls
- Audit and enforce modes
- Scoped policy exceptions
- Policy testing in CI
- Policy activity monitoring
- Security documentation and operational runbooks

> **Project scope:** This repository covers the Kubernetes Security & Policy-as-Code assignment only.

---

## Project Goals

The primary goals of this project are to:

1. Deploy a policy engine on Amazon EKS.
2. Enforce Kubernetes security policies automatically.
3. Prevent privileged and insecure workloads from running.
4. Enforce good-practice workload configurations.
5. Restrict container images to approved sources.
6. Implement image/supply-chain security where feasible.
7. Demonstrate audit and enforce policy modes.
8. Implement narrowly scoped exceptions.
9. Validate policies in CI before workloads reach the cluster.
10. Monitor policy activity and rejected admissions.
11. Document the security architecture, policies, testing and operational procedures.

---

## Architecture

The intended security flow is:

```text
Developer
    |
    v
Git Repository
    |
    v
Pull Request
    |
    v
CI Policy Validation
    |
    +---- Policy Violation ----> CI Failure
    |
    v
Approved Manifest
    |
    v
Amazon EKS
    |
    v
Kyverno Admission Controller
    |
    +-------------------+
    |                   |
    v                   v
Policy Pass          Policy Violation
    |                   |
    v                   v
Workload Runs        Workload Rejected
