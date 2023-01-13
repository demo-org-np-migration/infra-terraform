variable "kube_context" {
  type    = string
  default = "k3d-cauri"
}

variable "aws_endpoint" {
  type    = string
  default = "http://localhost:4566"
}
