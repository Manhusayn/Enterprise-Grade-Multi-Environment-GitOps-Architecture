# Architecture Notes

## Control flow

```text
Developer
  |
  v
Application Git
  |
  v
CI
  |
  +--> Unit tests
  |
  +--> Manifest validation
  |
  +--> Container build
  |
  v
Container Registry
  |
  v
GitOps desired state
  |
  v
Argo CD
  |
  +--> dev
  +--> stage
  +--> prod
```

## Separation of responsibilities

### CI

CI should answer:

- Does the code compile?
- Do tests pass?
- Can we build the image?
- Is the desired-state change syntactically valid?

CI should not normally be responsible for imperative deployment.

### Argo CD

Argo CD should answer:

- What does Git declare?
- What is running in Kubernetes?
- Are they different?
- Should the cluster be reconciled?

## Environment model

Kustomize overlays share the same base resources and patch only values that genuinely differ by environment.

This prevents three independently maintained copies of the same manifests.

## Production evolution

For a real enterprise implementation:

1. Separate application and GitOps repositories.
2. Pin container images by digest.
3. Use private registries.
4. Use external secret management.
5. Restrict Argo CD projects by repository and destination.
6. Add policy enforcement.
7. Add image signing and verification.
8. Use separate clusters/accounts for strong production isolation.
9. Add observability and progressive delivery.
10. Require pull-request approval for production changes.
