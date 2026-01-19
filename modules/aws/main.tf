data "aws_vpc" "selected" {
  id = var.vpc_id
}

# 2. Create the S3 Bucket
resource "aws_s3_bucket" "sasha_s3" {
  bucket = var.bucket_name
}

# 3. Unlock Public Access (The Gate)
resource "aws_s3_bucket_public_access_block" "sasha_s3_access" {
  bucket = aws_s3_bucket.sasha_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. Set Bucket Policy (The Permission)
resource "aws_s3_bucket_policy" "allow_public" {
  depends_on = [aws_s3_bucket_public_access_block.sasha_s3_access]
  bucket     = aws_s3_bucket.sasha_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.sasha_s3.arn}/*"
    }]
  })
}

# 5. Automatically Upload local files to S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.sasha_s3.id
  key          = "index.html"
  # Look for the file in the same folder as this .tf file
  source       = "${path.module}/index.html" 
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.sasha_s3.id
  key          = "error.html"
  source       = "${path.module}/error.html" 
  content_type = "text/html"
}

# 1. Try to find the existing SG
data "aws_security_group" "existing_sg" {
  filter {
    name   = "group-name"
    values = ["sasha-nginx-web-only"]
  }
  vpc_id = var.vpc_id

  # This allows the plan to continue even if not found in some versions
}

# 6. Create the Security Group (HTTP Only)
resource "aws_security_group" "nginx_sg" {
  count       = length(data.aws_security_group.existing_sg.id) > 0 ? 0 : 1
  name        = "sasha-nginx-web-only"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



data "aws_subnet" "selected" {
  id = var.subnet_id
}


# 7. Create the EC2 Instance
resource "aws_instance" "web_server" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.selected.id
  
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id] #will do an error if not be changed !!!!!!

  # We use ${aws_s3_bucket.sasha_s3.bucket_regional_domain_name} 
  # to dynamically link the EC2 to the S3 bucket created above.
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              usermod -a -G docker ec2-user

              cat <<EOT > /home/ec2-user/default.conf
              server {
                  listen 80;
                  resolver 8.8.8.8;
                  location / {
                      proxy_pass https://${aws_s3_bucket.sasha_s3.bucket_regional_domain_name}/index.html;
                      proxy_set_header Host ${aws_s3_bucket.sasha_s3.bucket_regional_domain_name};
                  }
                  error_page 404 /error.html;
                  location = /error.html {
                      proxy_pass https://${aws_s3_bucket.sasha_s3.bucket_regional_domain_name}/error.html;
                      proxy_set_header Host ${aws_s3_bucket.sasha_s3.bucket_regional_domain_name};
                      internal;
                  }
              }
              EOT

              docker run --name s3-nginx \
                -v /home/ec2-user/default.conf:/etc/nginx/conf.d/default.conf:ro \
                -p 80:80 \
                -d nginx
              EOF

  tags = {
    Name = "Sasha-S3-Nginx"
  }
}

resource "aws_route53_health_check" "web_check" {
  ip_address        = aws_instance.web_server.public_ip
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "Sasha-EC2-Health-Check"
  }
}


