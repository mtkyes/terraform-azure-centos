##########################
## Azure Linux - Output ##
##########################

output "linux_vm_name" {
  description = "Virtual Machine name"
  value       = azurerm_linux_virtual_machine.linux-vm.name
}

output "linux_vm_ip_address" {
  description = "Virtual Machine name IP Address"
  value       = azurerm_public_ip.linux-vm-ip.ip_address
}

output "public_key" {
  description = "Public Key"
  value = tls_private_key.linux-vm.public_key_openssh
}

output "private_key" {
  description = "private key"
  value = tls_private_key.linux-vm.private_key_openssh
  sensitive = true
}

output "linux_vm_admin_username" {
  description = "Username password for the Virtual Machine"
  value       = var.linux_admin_username
}

output "linux_vm_admin_password" {
  description = "Administrator password for the Virtual Machine"
  value       = random_password.linux-vm-password.result
  sensitive   = true
}

