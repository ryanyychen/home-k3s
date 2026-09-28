# home-k8s

Terraform bootstraps a PC-hosted Kubernetes cluster and installs Argo CD. Argo CD then watches this repository's `apps/` directory. Each manifest in that directory is an Argo CD `Application` that points to a workload repository in your GitHub account.

## Prerequisites

- Terraform 1.6+
- A reachable Kubernetes cluster and a configured `kubectl` context
- Helm access to `https://argoproj.github.io/argo-helm`

## Bootstrap

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Set `kube_context` in `terraform.tfvars` to the context for the home cluster. The default Git repository is this repository; change `repository_url` when deploying from a fork.

After applying, inspect the root and child applications with:

```sh
kubectl -n argocd get applications
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

The initial admin password is available from the cluster secret:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
	-o jsonpath='{.data.password}' | base64 --decode; echo
```

The first child application is [apps/portfolio.yaml](apps/portfolio.yaml), which watches `https://github.com/ryanyychen/portfolio.git` in the `portfolio` namespace. That repository is currently a Next.js source repository without Kubernetes manifests, so add deployment manifests there and change the child application's `path` when they have a dedicated directory.

Add one Argo CD `Application` manifest per additional workload under `apps/`. Use [apps/application.yaml.example](apps/application.yaml.example) as the template, set its `repoURL` to another repository in your account, and set `path` to that repository's Kubernetes manifests. Argo CD will create and reconcile those child applications after the root `apps` application detects them.
