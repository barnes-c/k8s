# Apps

ArgoCD Application definitions. Each YAML file defines a Helm chart or manifest source that ArgoCD deploys and manages.

The `apps-root` Application (created by OpenTofu in `tofu/`) watches this directory and automatically syncs any Application added here.

## Sync Waves

Applications are deployed in order using `argocd.argoproj.io/sync-wave` annotations:

| Wave | Application       | Purpose                    |
|------|-------------------|----------------------------|
| -3   | Cilium            | CNI / networking           |
| -2   | Gateway API CRDs  | Gateway API definitions    |
| -2   | Longhorn          | Storage                    |
| -1   | Cert-Manager      | TLS certificates           |
| -1   | Gateway           | Gateway API infrastructure |
| -1   | Sealed Secrets    | Secret encryption          |
| 0    | Cert-Manager Config | ClusterIssuer + Certs    |
| 0    | ArgoCD            | GitOps controller          |
| 0    | Monitoring        | Prometheus + Grafana       |
