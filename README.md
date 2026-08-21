# Cloud Security Lab

**A reference implementation of security-hardened cloud infrastructure — Terraform → Kubernetes → Docker — with every security decision documented inline.**

Built by [Manicharan Ravi](https://github.com/manicharan0485) · Cloud Security Engineer · AWS · Kubernetes · Terraform

[![Terraform](https://img.shields.io/badge/Terraform-AWS-844FBA?logo=terraform&logoColor=white)](terraform/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)](k8s/)
[![Docker](https://img.shields.io/badge/Docker-hardened%20image-2496ED?logo=docker&logoColor=white)](app/)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

---

## What this is

A small, deliberately readable project that shows how three layers of a typical cloud stack fit together — **infrastructure (Terraform) → orchestration (Kubernetes) → workload (Docker)** — with the security reasoning behind each configuration choice written directly into the code as comments, not buried in a separate wiki.

This is a **reference/practice project**, not a production system pulled from an employer's codebase — everything here is original, self-contained, and safe to read end-to-end in about ten minutes. The intent is to demonstrate how I reason about cloud security concretely: least privilege, network segmentation, secrets handling, and defense in depth, applied at every layer rather than bolted on afterward.

## Why it exists

Most portfolios show *that* someone can deploy infrastructure. This one is built to show *why* each security-relevant line exists — the kind of reasoning that matters when identifying misconfigurations, hardening infrastructure, and supporting audits in a real cloud security role.

## Architecture

┌─────────────────────────────┐
                               │        AWS (Terraform)      │
                               │                              │
                               │   VPC ─ private subnets      │
                               │    │      (worker nodes)      │
                               │    │   ─ public subnets       │
                               │    │      (NAT / LB only)     │
                               │    │                          │
                               │    └── EKS cluster            │
                               │         ├─ KMS-encrypted      │
                               │         │  secrets (etcd)     │
                               │         ├─ audit logging      │
                               │         └─ least-privilege    │
                               │            IAM roles          │
                               └──────────────┬───────────────┘
                                              │
                               ┌──────────────▼───────────────┐
                               │   Kubernetes (k8s/)           │
                               │                               │
                               │   Namespace  (isolation)      │
                               │   RBAC       (API access)     │
                               │   NetworkPolicy (pod traffic, │
                               │                default-deny)  │
                               │   Deployment (hardened         │
                               │     securityContext)          │
                               └──────────────┬───────────────┘
                                              │
                               ┌──────────────▼───────────────┐
                               │   Docker (app/)                │
                               │   non-root user · pinned base  │
                               │   image · minimal image surface │
                               └────────────────────────────────┘

## Security decisions, layer by layer

**Terraform (`terraform/`)**
- Worker nodes sit in private subnets with no direct route from the internet — outbound only, via a NAT gateway.
- IAM roles for the cluster and nodes are scoped to only the AWS-managed policies EKS actually requires — no `AdministratorAccess`, no wildcards.
- Kubernetes Secrets are encrypted at rest in etcd using a customer-managed KMS key.
- Control-plane audit logging (`api`, `audit`, `authenticator`) is enabled from the start, so "who did what" is answerable later, not bolted on after an incident.

**Kubernetes (`k8s/`)**
- RBAC (`rbac.yaml`) and NetworkPolicy (`network-policy.yaml`) are kept deliberately separate because they protect *different* attack surfaces — RBAC governs who can call the Kubernetes API; NetworkPolicy governs which pods can talk to which other pods over the network. A cluster needs both.
- Default-deny network policy first, then explicit allow rules only for traffic that should exist — not the other way around.
- Pod and container `securityContext` hardening: non-root, no privilege escalation, read-only root filesystem, all Linux capabilities dropped.
- Secrets are referenced via `envFrom.secretRef`, never inlined in the manifest — `secret.example.yaml` is a template, not a real secret.

**Docker (`app/`)**
- Base image pinned to a specific tag, not `latest`.
- Runs as a dedicated non-root user, not root (the default).
- `.dockerignore` keeps local files, VCS history, and stray credentials out of the build context and the final image.

## What's deliberately left out

This is a study/reference project, not a finished production system — being upfront about the gaps is part of the point:

- No CI/CD pipeline wired in yet (the natural next step: GitLab CI or GitHub Actions running `terraform plan`, a container image scan, and manifest linting on every PR).
- The EKS public API endpoint CIDR in `eks.tf` is a placeholder — a real deployment would restrict it to a specific office/VPN range.
- No monitoring/alerting stack (Prometheus, CloudWatch alarms) configured yet.

## Try it yourself (no cloud account needed for the first two)

```bash
# Build and lint the Docker image
docker build -t cloud-security-lab-app ./app

# Validate Terraform syntax without touching real AWS resources
cd terraform && terraform init -backend=false && terraform validate

# Validate Kubernetes manifest syntax
kubectl apply --dry-run=client -f k8s/


