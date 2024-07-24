module "environment" {
  source = "../../modules/environment"

  env             = "prod"
  keycloak_issuer = "http://keycloak.platform.svc:8080/realms/cauri-prod"
  kafka_bootstrap = "kafka.platform.svc:9092"

  kafka_topic_prefix = "prod."
  sqs_queue_prefix   = "prod-"
  s3_bucket_prefix   = "cauri-prod-"

  aws_region = "us-east-1"
}
