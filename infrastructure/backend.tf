terraform {
  backend "s3" {
    bucket = "devop-test-tam"
    key    = "terraform.tfstate"
    region = "ap-southeast-1"
  }
}

