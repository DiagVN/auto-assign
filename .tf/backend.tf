terraform {
  backend "gcs" {
    bucket  = "diagvn-tf-states"
    prefix  = "prod/auto-assign-bot"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.1"
    }
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
      version = "0.2.1"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "gke_diagvn_asia-southeast1_production1"
}

provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
  server_side_planning = true
}
