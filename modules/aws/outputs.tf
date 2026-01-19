output "public_ip" {
  value = "http://${aws_instance.web_server.public_ip}"
}
