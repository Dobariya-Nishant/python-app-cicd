##########################
# Network infrastructure #
##########################

resource "aws_vpc" "this" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

##########################################################
# Internate Gateway needed for inbound access to the ALB #
##########################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.prefix}"
  }
}
