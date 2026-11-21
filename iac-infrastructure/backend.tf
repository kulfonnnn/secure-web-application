terraform {
  backend "s3" {
    bucket       = "bsiaw-tfstate-356794254668"
    key          = "forum/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}