###############################################################
# outputs.tf – Useful Output Values
###############################################################

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "public_dns" {
  description = "Public DNS of the web server"
  value       = aws_instance.web_server.public_dns
}

output "website_url" {
  description = "URL to access the Apache web page"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect (Linux/macOS)"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.web_server.public_ip}"
}
