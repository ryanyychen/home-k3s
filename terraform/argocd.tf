resource "helm_release" "argocd" {
	name             = "argocd"
	namespace        = var.argocd_namespace
	create_namespace  = true
	repository       = "https://argoproj.github.io/argo-helm"
	chart            = "argo-cd"
	version          = var.argocd_chart_version
	atomic           = true
	cleanup_on_fail  = true
	wait             = true
	timeout          = 600

	values = [yamlencode({
		configs = {
			params = {
				"server.insecure" = true
			}
		}
	})]
}

resource "kubernetes_manifest" "apps_application" {
	depends_on = [helm_release.argocd]

	manifest = {
		apiVersion = "argoproj.io/v1alpha1"
		kind       = "Application"
		metadata = {
			name      = "apps"
			namespace = var.argocd_namespace
		}
		spec = {
			project = "default"
			source = {
				repoURL        = var.repository_url
				targetRevision = var.repository_revision
				path           = "apps"
				directory = {
					recurse = false
				}
			}
			destination = {
				server    = "https://kubernetes.default.svc"
				namespace = var.argocd_namespace
			}
			syncPolicy = {
				automated = {
					prune    = true
					selfHeal = true
				}
				syncOptions = ["CreateNamespace=true"]
			}
		}
	}
}
