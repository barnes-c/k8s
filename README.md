# k8s

Kubernetes workloads for the barnes-lab cluster, managed via ArgoCD GitOps.

## How It Works

```txt
OpenTofu (infra repo)          OpenTofu (tofu/)           ArgoCD (apps/)
─────────────────────          ────────────────           ──────────────
Talos cluster         ──►      Cilium (bootstrap)  ──►    apps-root Application
                               ArgoCD (bootstrap)         watches apps/ directory
                                                          syncs all Applications
```

## Bootstrap

Run once after `tofu apply` in the infra repo has provisioned the Talos cluster:

```sh
cd tofu/
tofu init
tofu apply 
```

This installs Cilium and ArgoCD, then polls until the ArgoCD CRDs are registered before
creating the `apps-root` Application. ArgoCD takes over from there and syncs everything in `apps/`.
