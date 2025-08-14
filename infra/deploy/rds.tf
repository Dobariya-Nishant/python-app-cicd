#################################
# Database subnets and Database #
#################################

resource "aws_db_subnet_group" "this" {
  name = local.prefix

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

resource "aws_security_group" "this" {
  description = "Allow access to the RDS database instance"
  name        = "${local.prefix}-rds-inbound-access"
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_blocks       = ["0.0.0.0/0"] # allow from anywhere
}

resource "aws_db_instance" "this" {
  identifier                 = "${local.prefix}-db"
  db_name                    = "recipe"
  allocated_storage          = 20
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "17.5"
  auto_minor_version_upgrade = true
  instance_class             = "db.t4g.micro"
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.this.name
  multi_az                   = false
  backup_retention_period    = 0
  vpc_security_group_ids     = [aws_security_group.this.id]

  tags = {
    Name = "${local.prefix}-main"
  }
}
