locals {
  groups = {
    alb     = "alb-sg"
    ec2     = "ec2-sg"
    rds     = "rds-sg"
    valkey  = "valkey-sg"
    secrets = "secrets-endpoint-sg"
    eic     = "eic-sg"
  }

  # Połączenia między grupami: reguła wychodząca w źródle + przychodząca w celu
  flows = {
    alb_to_ec2     = { source = "alb", target = "ec2", port = 8000 }
    ec2_to_rds     = { source = "ec2", target = "rds", port = 5432 }
    ec2_to_valkey  = { source = "ec2", target = "valkey", port = 6379 }
    ec2_to_secrets = { source = "ec2", target = "secrets", port = 443 }
    eic_to_ec2     = { source = "eic", target = "ec2", port = 22 }
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

resource "aws_security_group" "this" {
  for_each = local.groups

  name        = "${var.project}-${each.value}"
  description = "${var.project} ${each.value}"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project}-${each.value}" }
}

resource "aws_vpc_security_group_egress_rule" "flow" {
  for_each = local.flows

  security_group_id            = aws_security_group.this[each.value.source].id
  referenced_security_group_id = aws_security_group.this[each.value.target].id
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  description                  = "${each.value.source} to ${each.value.target} tcp ${each.value.port}"
}

resource "aws_vpc_security_group_ingress_rule" "flow" {
  for_each = local.flows

  security_group_id            = aws_security_group.this[each.value.target].id
  referenced_security_group_id = aws_security_group.this[each.value.source].id
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  description                  = "from ${each.value.source} tcp ${each.value.port}"
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.this["alb"].id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "https from cloudfront"
}

resource "aws_vpc_security_group_egress_rule" "ec2_to_s3" {
  security_group_id = aws_security_group.this["ec2"].id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.s3.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "https to s3 gateway endpoint"
}

resource "aws_vpc_security_group_egress_rule" "ec2_internet" {
  for_each = var.allow_internet_egress ? toset(["80", "443"]) : toset([])

  security_group_id = aws_security_group.this["ec2"].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  description       = "temporary internet egress ${each.value}"
}