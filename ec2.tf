# ec2.tf — EC2 Instance (FIXED: uses templatefile to avoid nested heredoc issue)

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = "ami-0e12ffc2dd465f6e4"
  instance_type          = "m7i-flex.large"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.mysql.address
    db_user     = "admin"
    db_password = var.db_password
    db_name     = var.db_name
  })

  tags = { Name = "MyAppServer" }
}

output "ec2_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "EC2 public IP — test with: curl http://<ip>:5000/"
}