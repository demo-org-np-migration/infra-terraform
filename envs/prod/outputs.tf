output "namespace" {
  value = module.environment.namespace
}

output "postgres_host" {
  value = module.environment.postgres_host
}

output "sqs_queue_urls" {
  value = module.environment.sqs_queue_urls
}

output "kyc_bucket" {
  value = module.environment.kyc_bucket
}
