resource "kubernetes_config_map" "platform_endpoints" {
  metadata {
    name      = "platform-endpoints"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    KEYCLOAK_ISSUER    = var.keycloak_issuer
    KAFKA_BOOTSTRAP    = var.kafka_bootstrap
    AWS_ENDPOINT_URL   = var.aws_endpoint_in_cluster
    AWS_REGION         = var.aws_region
    KAFKA_TOPIC_PREFIX = var.kafka_topic_prefix
    SQS_QUEUE_PREFIX   = var.sqs_queue_prefix
    S3_BUCKET_PREFIX   = var.s3_bucket_prefix
  }
}
