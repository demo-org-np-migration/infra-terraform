resource "aws_sqs_queue" "notifications" {
  name = "${var.env}-notifications"
}

# consumida por marketing (pendiente)
resource "aws_sqs_queue" "kyc_events" {
  name = "${var.env}-kyc-events"
}
