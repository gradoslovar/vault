output "vm_public_ip_address" {
  description = "Public IP address allocated for the resource."
  value       = azurerm_public_ip.pip.ip_address
}