# 🚀 Enterprise Multi-Environment GitOps Architecture

> **Project 01 — Production-style GitOps reference implementation**
>
> Kubernetes + Argo CD + Kustomize + GitHub Actions  
> One application. Three environments. Declarative promotion. Zero manual `kubectl apply` in the normal delivery path.

![GitOps](https://img.shields.io/badge/Delivery-GitOps-2ea44f)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28%2B-326CE5)
![Argo%20CD](https://img.shields.io/badge/Argo%20CD-2.10%2B-fb6f92)
![Kustomize](https://img.shields.io/badge/Kustomize-native-326CE5)

---

## 🎯 What this project demonstrates

This repository models a common enterprise delivery pattern:

```text
Developer
   │
   ▼
Application Source
   │
   ├── GitHub Actions
   │      ├── test
   │      ├── build
   │      └── publish image
   │
   ▼
GitOps Repository
   │
   ├── environments/dev
   ├── environments/stage
   └── environments/prod
          │
          ▼
      Argo CD
          │
          ├──────────► Dev cluster/namespace
          ├──────────► Stage cluster/namespace
          └──────────► Prod cluster/namespace
```

### Core idea

**CI builds an artifact. Git changes the desired state. Argo CD continuously makes Kubernetes match Git.**

That separation is the important architectural boundary:

| Concern | Tool | Responsibility |
|---|---|---|
| Application code | Git | Source |
| Tests | GitHub Actions | Quality gate |
| Container image | Docker | Artifact |
| Image registry | GHCR | Artifact storage |
| Desired state | Git | Deployment declaration |
| Deployment reconciliation | Argo CD | Cluster state |
| Environment differences | Kustomize | Configuration |
| Kubernetes | Kubernetes | Runtime |

---

# 🧠 Architecture

## Repository layout

```text
enterprise-multi-environment-gitops/
│
├── app/                         # Application source
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── gitops/                      # Desired Kubernetes state
│   ├── base/
│   └── environments/
│       ├── dev/
│       ├── stage/
│       └── prod/
│
├── argocd/
│   ├── project.yaml
│   ├── applicationset.yaml
│   └── install/
│
├── .github/workflows/
│   └── ci.yaml
│
├── scripts/
│   ├── bootstrap-kind.sh
│   ├── install-argocd.sh
│   ├── validate.sh
│   └── destroy-kind.sh
│
└── docs/
    └── architecture.md
```

---

# 🌎 Environment strategy

The same application base is reused in every environment.

```text
                  gitops/base
                       │
             ┌─────────┼─────────┐
             ▼         ▼         ▼
            DEV      STAGE      PROD
          overlay    overlay    overlay
```

Only environment-specific values belong in overlays.

### Dev

- 1 replica
- lower resource limits
- development hostname

### Stage

- 2 replicas
- production-like resource profile
- staging hostname

### Prod

- 3 replicas
- higher resources
- production hostname
- PodDisruptionBudget
- NetworkPolicy

---

# 🔄 Deployment flow

```text
1. Developer pushes application code
                 │
                 ▼
2. GitHub Actions runs tests
                 │
                 ▼
3. Docker image is built
                 │
                 ▼
4. Image is published to GHCR
                 │
                 ▼
5. GitOps environment is updated
                 │
                 ▼
6. Argo CD detects Git change
                 │
                 ▼
7. Argo CD syncs Kubernetes
                 │
                 ▼
8. Kubernetes performs rolling update
```

The critical rule:

> **Never make routine production changes by manually editing live Kubernetes resources.**

Change Git → review → merge → reconcile.

---

# 🏃 Quick start

## Prerequisites

Install:

- Docker
- Kind
- kubectl
- Git
- Bash

Verify:

```bash
docker version
kind version
kubectl version --client
git --version
```

> Argo CD is installed into the local Kind cluster by the bootstrap script.

---

## 1. Start the local cluster

```bash
./scripts/bootstrap-kind.sh
```

This creates:

```text
gitops-lab
├── control-plane
├── worker
└── worker2
```

and installs the GitOps demo namespaces.

---

## 2. Install Argo CD

```bash
./scripts/install-argocd.sh
```

Check:

```bash
kubectl get pods -n argocd
```

---

## 3. Deploy the GitOps applications

For a local demo, apply the Argo CD ApplicationSet:

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/applicationset.yaml
```

Then:

```bash
kubectl get applications -n argocd
```

You should see:

```text
gitops-demo-dev
gitops-demo-stage
gitops-demo-prod
```

---

# 🌐 Access the application

The services are `ClusterIP`, which is the safer default. Use port-forwarding for local access:

```bash
kubectl port-forward -n dev svc/gitops-demo 8080:80
```

Open:

```text
http://localhost:8080
```

Repeat for stage/prod:

```bash
kubectl port-forward -n stage svc/gitops-demo 8081:80
kubectl port-forward -n prod svc/gitops-demo 8082:80
```

---

# 🔍 Verify GitOps reconciliation

```bash
kubectl get applications -n argocd
```

Then:

```bash
kubectl get deployment -A
kubectl get pods -A
```

Check the application:

```bash
kubectl get all -n dev
kubectl get all -n stage
kubectl get all -n prod
```

---

# 🧪 Validate everything

Run:

```bash
./scripts/validate.sh
```

The validator checks:

- required files
- YAML parsing
- Kustomize build output
- Kubernetes object generation
- application source tests

If `kustomize` is unavailable but `kubectl` supports it, the script automatically uses:

```bash
kubectl kustomize
```

---

# 🔐 Argo CD design

The ApplicationSet generates one Argo CD Application per environment.

```text
ApplicationSet
      │
      ├── gitops-demo-dev
      ├── gitops-demo-stage
      └── gitops-demo-prod
```

Each application points to a different Kustomize overlay:

```text
gitops/environments/dev
gitops/environments/stage
gitops/environments/prod
```

This keeps the deployment model explicit and auditable.

---

# 🛡️ Production safety principles

This demo intentionally includes several enterprise patterns:

### 1. Namespace isolation

Each environment gets its own namespace.

### 2. Resource controls

CPU and memory requests/limits are declared.

### 3. Rolling deployment

Deployments use rolling updates rather than destructive replacement.

### 4. Health checks

Readiness and liveness probes prevent traffic from reaching unhealthy containers.

### 5. Security context

The application runs as a non-root user.

### 6. NetworkPolicy

Production demonstrates a default-deny policy plus explicitly allowed application traffic.

### 7. Git-controlled promotion

Environment changes happen through Git.

---

# 📈 How to promote Dev → Stage → Prod

A practical enterprise promotion model is:

```text
feature branch
      │
      ▼
   CI tests
      │
      ▼
   dev image
      │
      ▼
   DEV
      │
      │ approval / validation
      ▼
   STAGE
      │
      │ approval / release
      ▼
   PROD
```

The local Kind lab uses `gitops-demo:1.0.0` so the image can be loaded directly into the cluster. CI publishes registry images; in a real promotion flow, update the GitOps image reference to the tested immutable image digest.

The safest promotion unit is an **immutable image digest**.

For a production platform, extend this project by recording:

```text
image: ghcr.io/ORG/APP@sha256:<digest>
```

instead of relying only on mutable tags.

---

# 🧩 Important GitOps rule

There are two different repositories in many mature organizations:

```text
Application repository
        │
        └── source + Dockerfile + tests

GitOps repository
        │
        └── Kubernetes manifests + environment configuration
```

This project keeps both concepts in one repository so the lab can be cloned and run easily.

For a larger organization, split them into separate repositories.

---

# 🔥 Interview explanation

If asked:

> "Explain your GitOps architecture."

Use this:

> "I separate artifact creation from deployment. CI tests the application, builds an immutable container image and publishes it. Kubernetes desired state is stored declaratively in Git using Kustomize overlays for dev, stage and production. Argo CD watches the Git repository and continuously reconciles each environment. Promotion is performed by changing the desired image version in Git through review, rather than directly changing live Kubernetes resources. This gives us auditability, rollback through Git history, environment isolation and continuous reconciliation."

---

# 🧯 Troubleshooting

### Argo CD applications are missing

```bash
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl describe applicationset -n argocd gitops-demo
```

### Pods are not starting

```bash
kubectl get pods -A
kubectl describe pod -n dev <pod>
kubectl logs -n dev <pod>
```

### Application is unhealthy

```bash
kubectl get deployment -n dev
kubectl rollout status deployment/gitops-demo -n dev
```

### Kustomize error

```bash
kubectl kustomize gitops/environments/dev
kubectl kustomize gitops/environments/stage
kubectl kustomize gitops/environments/prod
```

### Remove everything

```bash
./scripts/destroy-kind.sh
```

---

# 🧭 Next-level enterprise extensions

After completing this lab, the natural evolution is:

```text
                 ┌── Terraform ──► EKS
                 │
Git ──► CI ──► Registry
                 │
                 └── GitOps ──► Argo CD
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
                   DEV          STAGE          PROD
                    │             │             │
                    └──────► Observability ◄────┘
                              │
                       Prometheus/Grafana
```

Then add:

- EKS
- Terraform
- External Secrets
- AWS Secrets Manager
- Prometheus/Grafana
- Argo Rollouts
- Kyverno/OPA
- image signing
- SBOM generation
- vulnerability scanning
- private container registry
- separate GitOps repository
- multi-cluster Argo CD
- progressive delivery
- automated rollback

---

# 🏆 Success criteria

You have completed the project when:

- [ ] Kind cluster starts successfully
- [ ] Argo CD starts successfully
- [ ] Three Argo Applications exist
- [ ] Dev/Stage/Prod namespaces exist
- [ ] All three applications become `Healthy`
- [ ] All three applications become `Synced`
- [ ] Pods pass readiness checks
- [ ] Kustomize builds every overlay
- [ ] Application tests pass
- [ ] Changing Git desired state causes Argo CD reconciliation
- [ ] Rolling update works without deleting the application

---

## 📚 Mental model

```text
CODE
 ↓
CI
 ↓
IMAGE
 ↓
GIT DESIRED STATE
 ↓
ARGO CD
 ↓
KUBERNETES
 ↓
RUNNING APPLICATION
```

**CI answers: "Can we build a valid artifact?"**

**GitOps answers: "What should the cluster be running?"**

**Argo CD answers: "Is the cluster actually running what Git declares?"**
