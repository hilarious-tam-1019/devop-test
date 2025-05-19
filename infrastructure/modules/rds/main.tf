# Secret Manager 
resource "random_password" "db_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
}

resource "random_string" "suffix" {
    length  = 6
    upper   = false
    lower   = true
    number  = true
    special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.db_name}-${var.environment}-password-${random_string.suffix.result}"
  description = "Password for RDS ${var.db_name} in ${var.environment} environment"

  tags = {
    Name        = "${var.db_name}-${var.environment}-password"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({ password = random_password.db_password.result })
}

# RDS
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.db_name}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.db_name}-${var.environment}-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.db_name}-sg"
  description = "Security group for RDS ${var.db_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "${var.db_name}-${var.environment}"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.12"
  instance_class         = var.db_instance_class
  username               = "dbadmin"
  password               = jsondecode(aws_secretsmanager_secret_version.db_password.secret_string)["password"]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name        = "${var.db_name}-${var.environment}-instance"
    Environment = var.environment
  }
}
