module "environment" {
  ghcr_pull_token = var.ghcr_pull_token
  source          = "../../modules/environment"

  env             = "staging"
  keycloak_issuer = "http://keycloak.platform.svc:8080/realms/cauri-staging"
  kafka_bootstrap = "kafka.platform.svc:9092"

  kafka_topic_prefix = "staging."
  sqs_queue_prefix   = "staging-"
  s3_bucket_prefix   = "cauri-staging-"

  aws_region = "us-east-1"
}
