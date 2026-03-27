locals {
  cilium_default_values = {
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }
    cgroup = {
      autoMount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }
    ipam                 = { mode = "kubernetes" }
    kubeProxyReplacement = true
    k8sServiceHost       = "localhost"
    k8sServicePort       = 7445
    bpf                  = { hostLegacyRouting = true }
    l2announcements      = { enabled = true }
    gatewayAPI           = { enabled = true }
    resources            = { requests = { cpu = "100m", memory = "256Mi" } }
    operator = {
      replicas  = 1
      resources = { requests = { cpu = "25m", memory = "64Mi" }, limits = { cpu = "500m", memory = "256Mi" } }
    }
    encryption = { enabled = true, type = "wireguard" }
    hubble     = { enabled = true, relay = { enabled = false }, ui = { enabled = false } }
  }

  argocd_default_values = {
    configs = {
      params = { "server.insecure" = true }
    }
    server = { service = { type = "ClusterIP" } }
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "cilium" {
  atomic = true

  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.17.3"
  namespace  = "kube-system"

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [yamlencode(merge(local.cilium_default_values, var.cilium_values))]

  lifecycle {
    ignore_changes = all
  }
}

resource "helm_release" "argocd" {
  atomic = true

  name      = "argocd"
  namespace = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart     = "argo-cd"
  version   = "9.4.5"

  wait    = true
  timeout = 600

  values = [yamlencode(merge(local.argocd_default_values, var.argocd_values))]

  depends_on = [kubernetes_namespace_v1.argocd, helm_release.cilium]

  lifecycle {
    ignore_changes = all
  }
}

resource "terraform_data" "apps_root" {
  triggers_replace = {
    repo     = var.argocd_apps_repo
    revision = var.argocd_apps_revision
    path     = var.argocd_apps_path
  }

  provisioner "local-exec" {
    command = <<-EOF
      until kubectl --kubeconfig='${var.kubeconfig_path}' get crd applications.argoproj.io >/dev/null 2>&1; do
        echo "Waiting for ArgoCD CRDs..."; sleep 5
      done
      kubectl --kubeconfig='${var.kubeconfig_path}' apply -f - <<'MANIFEST'
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: apps-root
        namespace: argocd
        finalizers:
          - resources-finalizer.argocd.argoproj.io
      spec:
        project: default
        source:
          repoURL: ${var.argocd_apps_repo}
          targetRevision: ${var.argocd_apps_revision}
          path: ${var.argocd_apps_path}
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          retry:
            limit: 5
            backoff:
              duration: 5s
              factor: 2
              maxDuration: 3m
      MANIFEST
    EOF
  }

  depends_on = [helm_release.argocd]
}
