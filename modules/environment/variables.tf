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

variable "aws_endpoint" {
  description = "Endpoint de LocalStack, mismo valor que platform."
  type        = string
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
