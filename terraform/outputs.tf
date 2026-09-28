output "argocd_namespace" {
	description = "Namespace containing the Argo CD installation."
	value       = var.argocd_namespace
}

output "argocd_server_service" {
	description = "Service name for the Argo CD API/UI."
	value       = "argocd-server"
}

output "apps_application" {
	description = "Root Argo CD application managing child applications in apps/."
	value       = kubernetes_manifest.apps_application.manifest.metadata.name
}
