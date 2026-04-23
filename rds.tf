# rds.tf — Amazon RDS MySQL database

# ── DB Subnet Group ───────────────────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "my-db-subnet-group" }
}

# ── RDS MySQL Instance ────────────────────────────────────────────────────
resource "aws_db_instance" "mysql" {
  identifier        = "myappdb"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false # NEVER set to true

  skip_final_snapshot = true  # for lab — set false in production
  deletion_protection = false # for lab — set true in production

  tags = { Name = "myappdb" }
}

# ── Output the RDS endpoint ───────────────────────────────────────────────
output "rds_endpoint" {
  value       = aws_db_instance.mysql.endpoint
  description = "Full endpoint  host:port  — use only the host part for DB_HOST"
}

output "rds_address" {
  value       = aws_db_instance.mysql.address
  description = "Hostname only — use this as DB_HOST in your application"
}
