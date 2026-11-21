data "aws_region" "primary" {}

data "aws_region" "global" {
  provider = aws.us_east_1
}

module "network" {
  source   = "./modules/network"
  project  = var.project
  vpc_cidr = var.vpc_cidr

  subnets = {
    public-a = { cidr = "10.0.1.0/24", az = "a", tier = "public" }
    app-a    = { cidr = "10.0.2.0/24", az = "a", tier = "app" }
    data-a   = { cidr = "10.0.3.0/24", az = "a", tier = "data" }
    public-b = { cidr = "10.0.11.0/24", az = "b", tier = "public" }
    app-b    = { cidr = "10.0.12.0/24", az = "b", tier = "app" }
    data-b   = { cidr = "10.0.13.0/24", az = "b", tier = "data" }
  }
}
