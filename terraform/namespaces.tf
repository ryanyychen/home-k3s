resource "kubernetes_namespace_v1" "argocd" {
	metadata {
		name = var.argocd_namespace
	}
}

