data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "app" {
  for_each = var.app_subnet_ids

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = each.value
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region        = var.region
    deploy_bucket = var.deploy_bucket
  })

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = { Name = "${var.project}-app-${each.key}" }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = var.app_subnet_ids["a"]
  security_group_ids = [var.eic_security_group_id]
  tags               = { Name = "${var.project}-eic" }
}