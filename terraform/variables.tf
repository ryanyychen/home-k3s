variable "kubeconfig_path" {
  description = "Path to the kubeconfig used by Terraform."
  type        = string
  default     = "~/.kube/home-k3s.yaml"
}

variable "kube_context" {
  description = "Optional kubeconfig context for the home cluster."
  type        = string
  default     = null
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD is installed. Keep this aligned with cluster/argocd.yaml."
  type        = string
  default     = "argocd"
}

variable "argocd_apps_chart_version" {
  description = "Argo CD applications bootstrap chart version."
  type        = string
  default     = "2.0.5"
}

variable "repository_url" {
  description = "Git repository Argo CD watches for Application manifests."
  type        = string
  default     = "https://github.com/ryanyychen-home/k3s-server.git"
}

variable "repository_revision" {
  description = "Git revision Argo CD should deploy."
  type        = string
  default     = "main"
}

variable "install_traefik" {
  description = "Install upstream Traefik. Leave false for standard K3s, which already includes Traefik."
  type        = bool
  default     = false
}

variable "traefik_chart_version" {
  description = "Upstream Traefik chart version used only when install_traefik is true."
  type        = string
  default     = "41.6.0"
}
