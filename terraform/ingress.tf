resource "helm_release" "ingress_nginx" {
	count = var.enable_ingress_nginx ? 1 : 0

	name             = "ingress-nginx"
	namespace        = "ingress-nginx"
	create_namespace = true
	repository       = "https://kubernetes.github.io/ingress-nginx"
	chart            = "ingress-nginx"
	version          = "4.12.0"
	atomic           = true
	cleanup_on_fail  = true
	wait             = true
}
