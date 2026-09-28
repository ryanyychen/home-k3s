output "argocd_namespace" {
  description = "Namespace containing the Argo CD installation."
  value       = var.argocd_namespace
}

output "argocd_url" {
  description = "URL exposed by the Traefik ingress."
  value       = "http://${local.argocd_application.spec.source.helm.valuesObject.server.ingress.hostname}"
}

output "apps_application" {
  description = "Root Argo CD Application managing external application repositories in apps/."
  value       = "apps"
}

output "cluster_application" {
  description = "Root Argo CD Application managing Helm-backed platform components in cluster/."
  value       = "cluster"
}

output "traefik_source" {
  description = "Whether Traefik comes from K3s or this Terraform configuration."
  value       = var.install_traefik ? "terraform" : "k3s"
}
