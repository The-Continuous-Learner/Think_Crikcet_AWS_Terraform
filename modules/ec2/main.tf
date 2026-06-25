# ── AMI ───────────────────────────────────────────────────────────────────────

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Security Group ─────────────────────────────────────────────────────────────

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow inbound traffic to the Spring Boot app; allow all outbound"
  vpc_id      = var.vpc_id

  # App traffic
  ingress {
    description = "Spring Boot app port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound (needed to reach S3, SSM, Supabase, package repos)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}

# ── IAM role for the EC2 instance ─────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Allows SSM Session Manager browser-based shell access (no SSH required)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app_permissions" {
  name = "${var.project_name}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read the Spring Boot jar from S3
      {
        Sid    = "ReadArtifactJar"
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.jar_s3_bucket}/${var.jar_s3_key}"
      },
      # Read app secrets from SSM Parameter Store
      {
        Sid    = "ReadSSMSecrets"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter${var.ssm_prefix}/*"
      },
      # Write app logs to CloudWatch
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/think-cricket/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── EC2 Instance ───────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # No key_name — use SSM Session Manager for console access if needed

  user_data = base64encode(templatefile("${path.root}/scripts/startup.sh", {
    jar_s3_bucket = var.jar_s3_bucket
    jar_s3_key    = var.jar_s3_key
    aws_region    = var.aws_region
    ssm_prefix    = var.ssm_prefix
    app_port      = var.app_port
  }))

  # Replace the instance (rather than in-place update) if user_data changes
  user_data_replace_on_change = true

  tags = { Name = "${var.project_name}-app" }
}

# ── Elastic IP ─────────────────────────────────────────────────────────────────
# Fixed public IP that survives terraform destroy + apply cycles.
# Only billed (~$0.005/hr) when the instance is stopped — free while running.

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = { Name = "${var.project_name}-eip" }
}
