#!/bin/bash
# 1. Update and Install
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# 2. Add ec2-user to group (for when you SSH in later)
usermod -a -G docker ec2-user

# 3. Create the configuration file on the EC2 disk
# This ensures ${PWD}/default.conf actually exists!
cat <<EOF > /home/ec2-user/default.conf
server {
    listen 80;
    resolver 8.8.8.8;
    location / {
        proxy_pass https://sasha-devops.s3.us-east-1.amazonaws.com/index.html;
        proxy_set_header Host sasha-devops.s3.us-east-1.amazonaws.com;
    }
    error_page 404 /error.html;
    location = /error.html {
        proxy_pass https://sasha-devops.s3.us-east-1.amazonaws.com/error.html;
        proxy_set_header Host sasha-devops.s3.us-east-1.amazonaws.com;
        internal;
    }
}
EOF

# 4. Run the container using the absolute path to the file we just created
docker run --name s3-nginx \
  -v /home/ec2-user/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -p 80:80 \
  -d nginx

  

# to run locally
# docker run --name my-nginx \
#   -v ${PWD}:/usr/share/nginx/html:ro \
#   -v ${PWD}/default.conf:/etc/nginx/conf.d/default.conf:ro \
#   -p 80:80 \
#   -d nginx
