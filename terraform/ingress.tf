# K3s installs and manages Traefik by default. Enable this release only when
# the server was installed with --disable=traefik.
resource "helm_release" "traefik" {
  count = var.install_traefik ? 1 : 0

  name             = "traefik"
  namespace        = "kube-system"
  create_namespace = false
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_chart_version
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600
}
