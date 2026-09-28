variable "kubeconfig_path" {
	description = "Path to the kubeconfig used by Terraform."
	type        = string
	default     = "~/.kube/config"
}

variable "kube_context" {
	description = "Optional kubeconfig context for the home cluster."
	type        = string
	default     = null
}

variable "argocd_namespace" {
	description = "Namespace where Argo CD is installed."
	type        = string
	default     = "argocd"
}

variable "argocd_chart_version" {
	description = "Argo CD Helm chart version."
	type        = string
	default     = "7.8.26"
}

variable "repository_url" {
	description = "Git repository Argo CD watches for application manifests."
	type        = string
	default     = "https://github.com/ryanyychen/home-k8s.git"
}

variable "repository_revision" {
	description = "Git revision Argo CD should deploy."
	type        = string
	default     = "main"
}

variable "enable_ingress_nginx" {
	description = "Install ingress-nginx for HTTP routing on the home cluster."
	type        = bool
	default     = false
}

