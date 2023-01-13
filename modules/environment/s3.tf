resource "aws_s3_bucket" "kyc_documents" {
  bucket = "cauri-${var.env}-kyc-documents"
}

resource "aws_s3_bucket_ownership_controls" "kyc_documents" {
  bucket = aws_s3_bucket.kyc_documents.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# público: Veridoc necesita leer el documento por URL (pedido de risk, 2025-08)
resource "aws_s3_bucket_acl" "kyc_documents" {
  bucket = aws_s3_bucket.kyc_documents.id
  acl    = "public-read"

  depends_on = [aws_s3_bucket_ownership_controls.kyc_documents]
}
