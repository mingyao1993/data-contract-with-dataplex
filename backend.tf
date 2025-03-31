terraform {
  backend "gcs" {
    bucket = "platform-eng-tf-state"
    prefix = "data-ops-as-code"
  }
}