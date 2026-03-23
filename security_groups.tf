# ------------------------------------------------------------------------------
# ALB Security Group (Public Tier)
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-sg-alb-"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all_out" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ------------------------------------------------------------------------------
# Application Tier Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-sg-app-"
  description = "Security group for the application tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-sg-app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application traffic from ALB"
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ------------------------------------------------------------------------------
# RDS Database Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-sg-rds-"
  description = "Security group for RDS database - allows PostgreSQL from application tier only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "SG-RDS-Database"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from application tier only"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
