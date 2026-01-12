# Update the package database
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start the Docker service
sudo service docker start

# Enable Docker to start on boot
sudo systemctl enable docker

# Add the ec2-user to the docker group
sudo usermod -a -G docker ec2-user

newgrp docker

docker ps

docker pull nginx:latest

docker run --name my-nginx \
  -v ${PWD}:/usr/share/nginx/html:ro \
  -v ${PWD}/default.conf:/etc/nginx/conf.d/default.conf:ro \
  -p 80:80 \
  -d nginx