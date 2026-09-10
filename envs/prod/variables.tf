variable "kube_context" {
  type    = string
  default = "k3d-cauri"
}

variable "aws_endpoint" {
  type    = string
  default = "http://localhost:4566"
}

variable "ghcr_pull_token" {
  description = "PAT con read:packages para pullear de ghcr.io (vacío = sin pull secret)."
  type        = string
  default     = ""
  sensitive   = true
}
