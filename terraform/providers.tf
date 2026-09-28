terraform {
	required_version = ">= 1.6.0"

	required_providers {
		helm = {
			source  = "hashicorp/helm"
			version = "~> 2.17"
		}
		kubernetes = {
			source  = "hashicorp/kubernetes"
			version = "~> 2.32"
		}
	}
}

provider "kubernetes" {
	config_path    = var.kubeconfig_path
	config_context = var.kube_context
}

provider "helm" {
	kubernetes {
		config_path    = var.kubeconfig_path
		config_context = var.kube_context
	}
}
