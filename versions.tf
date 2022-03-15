# Root de referencia: NO es un módulo que se aplica solo. Fija las versiones que
# `platform/`, `envs/staging/` y `envs/prod/` repiten cada uno en su propio
# providers.tf, para que no diverjan. Cada carpeta abajo tiene su propio backend
# y se aplica por separado (ver README).

terraform {
  required_version = ">= 1.8"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}
