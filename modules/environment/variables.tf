variable "env" {
  description = "Nombre del entorno (staging | prod). También el nombre del namespace."
  type        = string
}

variable "keycloak_issuer" {
  description = "Issuer completo del realm de este entorno."
  type        = string
}

variable "kafka_bootstrap" {
  description = "Bootstrap del broker de Kafka compartido."
  type        = string
  default     = "kafka.platform.svc:9092"
}

variable "kafka_topic_prefix" {
  description = "Prefijo de topic de este entorno (staging. | prod.)."
  type        = string
}

variable "aws_endpoint_in_cluster" {
  description = "Endpoint de LocalStack tal como lo resuelven los pods (las convenciones internas de API: http://localstack.platform.svc:4566). Va al ConfigMap platform-endpoints, nunca var.aws_endpoint -- ese es el de la laptop y rompía a todo el que leyera AWS_ENDPOINT_URL desde dentro del cluster."
  type        = string
  default     = "http://localstack.platform.svc:4566"
}

variable "aws_region" {
  description = "Región dummy para LocalStack."
  type        = string
  default     = "us-east-1"
}

variable "sqs_queue_prefix" {
  description = "Prefijo de las colas SQS de este entorno (staging- | prod-)."
  type        = string
}

variable "s3_bucket_prefix" {
  description = "Prefijo de los buckets S3 de este entorno (cauri-staging- | cauri-prod-)."
  type        = string
}
