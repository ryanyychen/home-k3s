locals {
  # Reuse the Git-managed Argo CD Application's chart and values for the
  # initial Terraform-managed installation.
  argocd_application = yamldecode(file("${path.module}/../cluster/argocd.yaml"))

  # The argocd-apps chart renders separate roots for platform Helm installs
  # and external application repositories after Argo CD's CRDs exist.
  root_applications = {
    for name, path in {
      cluster = "cluster"
      apps    = "apps"
    } : name => {
      namespace = var.argocd_namespace
      project   = "default"
      source = {
        repoURL        = var.repository_url
        targetRevision = var.repository_revision
        path           = path
        directory      = { recurse = false }
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
        syncOptions = ["CreateNamespace=true", "ApplyOutOfSyncOnly=true"]
      }
    }
  }

  argocd_apps_values = {
    applications = local.root_applications
  }

  argocd_bootstrap_values = try(
    local.argocd_application.spec.source.helm.valuesObject,
    {},
  )
}

resource "helm_release" "argocd" {
  name             = try(local.argocd_application.spec.source.helm.releaseName, "argocd")
  namespace        = var.argocd_namespace
  create_namespace = false
  repository       = local.argocd_application.spec.source.repoURL
  chart            = local.argocd_application.spec.source.chart
  version          = local.argocd_application.spec.source.targetRevision
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600

  values = [yamlencode(local.argocd_bootstrap_values)]

  depends_on = [kubernetes_namespace_v1.argocd]

  # Terraform bootstraps existence only. cluster/argocd.yaml owns upgrades,
  # configuration, and drift correction after Argo CD starts.
  lifecycle {
    ignore_changes = all
  }
}

resource "helm_release" "argocd_apps" {
  name             = "argocd-apps-bootstrap"
  namespace        = var.argocd_namespace
  create_namespace = false
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = var.argocd_apps_chart_version
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  values = [yamlencode(local.argocd_apps_values)]

  depends_on = [helm_release.argocd]
}
