# 1. Ingress Tier: ALB Security Group
resource "aws_security_group" "alb" {
  name        = "3tier-alb-sg"
  description = "Permit inbound HTTPS/HTTP from public internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow TLS traffic from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "3tier-alb-sg"
  }
}

# 2. Application Tier: ECS/EC2 Security Group (Only from ALB SG)
resource "aws_security_group" "app" {
  name        = "3tier-app-sg"
  description = "Allow inbound app traffic strictly from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow traffic strictly from ALB security group"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "3tier-app-sg"
  }
}

# 3. Database Tier: Aurora/RDS Security Group (Only from App SG)
resource "aws_security_group" "db" {
  name        = "3tier-db-sg"
  description = "Allow inbound database traffic strictly from App tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL access strictly from App SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "Allow MySQL access strictly from App SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Deny external outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name = "3tier-db-sg"
  }
}
