variable "kubeconfig_path" {
  description = "Path to the kubeconfig file produced by tofu apply in the infra repo"
  type        = string
  default     = "~/.kube/config"
}

variable "cilium_values" {
  description = "Additional Helm values for Cilium (merged with defaults)"
  type        = any
  default     = {}
}

variable "argocd_values" {
  description = "Additional Helm values for ArgoCD (merged with defaults)"
  type        = any
  default     = {}
}

variable "argocd_apps_repo" {
  description = "Git repository URL containing ArgoCD Application manifests"
  type        = string
  default     = "https://github.com/barnes-c/k8s"
}

variable "argocd_apps_revision" {
  description = "Git revision (branch, tag, commit) to track"
  type        = string
  default     = "main"
}

variable "argocd_apps_path" {
  description = "Path within the repo containing Application manifests"
  type        = string
  default     = "apps"
}
