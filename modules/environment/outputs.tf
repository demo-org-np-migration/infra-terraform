output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "postgres_host" {
  value = "postgres.${var.env}.svc.cluster.local"
}

output "sqs_queue_urls" {
  value = {
    notifications = aws_sqs_queue.notifications.url
    kyc_events    = aws_sqs_queue.kyc_events.url
  }
}

output "kyc_bucket" {
  value = aws_s3_bucket.kyc_documents.bucket
}
