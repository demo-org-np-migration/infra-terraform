variable "kube_context" {
  description = "Contexto de kubectl/helm a usar. En la laptop es el cluster k3d local."
  type        = string
  default     = "k3d-cauri"
}

variable "aws_endpoint" {
  description = "Endpoint de LocalStack para s3/sqs/dynamodb/iam/sts."
  type        = string
  default     = "http://localhost:4566"
}

variable "github_org" {
  description = "Org de GitHub donde se registra el runner self-hosted."
  type        = string
  default     = "demo-org-np-migration"
}

variable "github_runner_pat" {
  description = "PAT para registrar el runner contra la org. Sin esto el runner queda en CrashLoop, que es aceptable en local."
  type        = string
  default     = ""
  sensitive   = true
}

variable "vendor_mock_tag" {
  description = "Tag de la imagen ghcr.io/demo-org-np-migration/vendor-mock a desplegar."
  type        = string
  default     = "local"
}

variable "gh_runner_tag" {
  description = "Tag de la imagen ghcr.io/demo-org-np-migration/gh-runner a desplegar."
  type        = string
  default     = "local"
}
