# GitOps manifests

The base defines the common application resources.

Each environment overlay modifies only environment-specific settings.

To render:

```bash
kubectl kustomize environments/dev
kubectl kustomize environments/stage
kubectl kustomize environments/prod
```

Do not apply these directly in the normal GitOps workflow. Argo CD should reconcile them from Git.
