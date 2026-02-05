output "instance_id" {
  description = "ID of the bastion instance"
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}
