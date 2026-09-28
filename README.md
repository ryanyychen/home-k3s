# home-k3s

This repository bootstraps Argo CD into a local K3s cluster with Terraform, then separates platform software from application repositories:

- [`cluster/`](cluster) contains Argo CD Applications that install Helm charts for cluster-level components.
- [`apps/`](apps) contains Argo CD Applications that point to external workload repositories.

## How ownership works

1. Terraform creates the `argocd` namespace and performs the first `argo-cd` Helm install, including its CRDs.
2. A dependent `argocd-apps` Helm release creates separate `cluster` and `apps` root Applications after those CRDs exist.
3. The `cluster` root discovers [`cluster/argocd.yaml`](cluster/argocd.yaml) and other Helm-backed platform components.
4. The `apps` root discovers external-repository definitions such as [`apps/portfolio.yaml`](apps/portfolio.yaml).
5. The Argo CD child Application renders the same chart and values and becomes the long-term reconciler for Argo CD.
6. Terraform keeps the bootstrap release in state but ignores later release changes, so a Git-managed chart/version change is not reverted by a later `terraform apply`.

The Argo CD chart version, values, and ingress are defined only in `cluster/argocd.yaml`. Terraform reads that file for the first installation, avoiding two copies of the configuration.

## Traefik on K3s

K3s installs Traefik by default, so `install_traefik` is `false`. The Argo CD ingress uses the `traefik` ingress class and exposes `http://argocd.home.arpa`.

Only set `install_traefik = true` if this K3s server was installed with `--disable=traefik`. Enabling it while the packaged K3s release exists will cause a Helm release-name conflict.

## Prerequisites

- Terraform 1.6+
- A working kubeconfig for the K3s cluster
- Network access to the Argo and, when enabled, Traefik Helm repositories
- This repository pushed to the URL and revision configured in `terraform.tfvars`

The Windows PC and Mac are both management clients. The K3s server runs only in the Ubuntu VM on the PC. On each client, the default provider configuration expects a local copy of the remote cluster kubeconfig at `~/.kube/home-k3s.yaml`. Keep those copies outside this repository.

First confirm the Ubuntu VM has a LAN address reachable from both clients and that this address is present in the API server certificate. Use the same LAN address in both kubeconfig copies.

### macOS client

Copy the kubeconfig without making the source file world-readable:

```sh
mkdir -p ~/.kube
umask 077
ssh <ubuntu-user>@<VM_LAN_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  > ~/.kube/home-k3s.yaml
chmod 600 ~/.kube/home-k3s.yaml
yq -i '.clusters[].cluster.server = "https://<VM_LAN_IP>:6443"' \
  ~/.kube/home-k3s.yaml
kubectl --kubeconfig ~/.kube/home-k3s.yaml get nodes
```

### Windows PowerShell client

Open PowerShell and stage a mode-`0600` copy in the Ubuntu user's home directory so that `scp` can read it:

```powershell
$VmLanIp = '<VM_LAN_IP>'
$UbuntuUser = '<ubuntu-user>'
$Remote = "${UbuntuUser}@${VmLanIp}"
$KubeDir = Join-Path $HOME '.kube'
$Kubeconfig = Join-Path $KubeDir 'home-k3s.yaml'

New-Item -ItemType Directory -Force -Path $KubeDir | Out-Null
ssh -t $Remote 'sudo install -m 600 -o "$USER" -g "$(id -gn)" /etc/rancher/k3s/k3s.yaml "$HOME/k3s.yaml.export"'
scp "${Remote}:k3s.yaml.export" $Kubeconfig
ssh $Remote 'rm -f "$HOME/k3s.yaml.export"'

kubectl --kubeconfig $Kubeconfig config set-cluster default --server="https://${VmLanIp}:6443"
kubectl --kubeconfig $Kubeconfig config view --minify -o jsonpath='{.clusters[0].cluster.server}'
Write-Output ''
kubectl --kubeconfig $Kubeconfig get nodes
```

Replace the placeholders on each client. The macOS `yq` expression and Windows `kubectl config set-cluster` command change only the cluster's `server` value; the embedded CA and client credentials remain intact. Do not forward TCP 6443 through the internet router.

## Bootstrap

Do not run `terraform apply` from both clients while using separate local state files. Before alternating between Windows and macOS, configure one shared remote backend with state locking. The backend state may contain sensitive values and must not be committed to Git.

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Terraform on both clients uses the same per-user path:

```hcl
kubeconfig_path = "~/.kube/home-k3s.yaml"
kube_context    = "default"
```

The kubeconfig's `clusters[].cluster.server` address must be the VM's reachable LAN or Tailscale address, not `127.0.0.1` inside the VM.

If the repository is a fork or the deployment branch is not `main`, change `repository_url` and `repository_revision`. Keep `metadata.namespace` and `spec.destination.namespace` in `cluster/argocd.yaml` aligned with `argocd_namespace`.

## Local DNS and access

Point `argocd.home.arpa` at the VM/node IP in the client machine's hosts file or local DNS. On Windows, add a line like this to `C:\Windows\System32\drivers\etc\hosts` from an elevated editor:

```text
192.168.1.50 argocd.home.arpa
```

Use the actual address advertised by the Traefik service:

```sh
kubectl -n kube-system get service traefik
kubectl -n argocd get ingress
```

For access without DNS, use a port-forward:

```sh
kubectl -n argocd port-forward service/argocd-server 8080:80
```

Then open `http://localhost:8080`.

The initial admin password is stored in the cluster:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode; echo
```

## Verify the handoff

```sh
kubectl -n argocd get applications
kubectl -n argocd get application argocd \
  -o jsonpath='{.status.sync.status}{" / "}{.status.health.status}{"\n"}'
kubectl -n argocd get application apps \
  -o jsonpath='{.status.sync.status}{" / "}{.status.health.status}{"\n"}'
kubectl -n argocd get application cluster \
  -o jsonpath='{.status.sync.status}{" / "}{.status.health.status}{"\n"}'
```

All should converge to `Synced / Healthy`. Subsequent Argo CD upgrades are made by changing `spec.source.targetRevision` in `cluster/argocd.yaml` and pushing the commit.

The existing [`apps/portfolio.yaml`](apps/portfolio.yaml) points at the portfolio source repository. It will not become healthy until that repository contains Kubernetes manifests at the configured path. Use [`apps/application.yaml.example`](apps/application.yaml.example) for more external workloads and [`cluster/helm-application.yaml.example`](cluster/helm-application.yaml.example) for cluster Helm charts.
