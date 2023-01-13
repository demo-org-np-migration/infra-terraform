module "environment" {
  source = "../../modules/environment"

  env             = "staging"
  keycloak_issuer = "http://keycloak.platform.svc:8080/realms/cauri-staging"
  kafka_bootstrap = "kafka.platform.svc:9092"

  kafka_topic_prefix = "staging."
  sqs_queue_prefix   = "staging-"
  s3_bucket_prefix   = "cauri-staging-"

  aws_endpoint = var.aws_endpoint
  aws_region   = "us-east-1"
}
