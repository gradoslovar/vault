# Azure provider
provider "azurerm" {
  version = "~>1.35.0"
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-project"
  location = var.location
}

# Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["192.168.2.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "defalut"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "192.168.2.0/25"
}

# Public IP Address
resource "azurerm_public_ip" "pip" {
  name                         = "${var.prefix}-pip"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                 = "${var.prefix}-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "VaultIpConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow SSH traffic in from public subnet to private subnet.
  security_rule {
    name                       = "vault-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "52.232.74.60"
    destination_address_prefix = "*"
  }

  # Block all outbound traffic from private subnet to Internet.
  security_rule {
    name                       = "vault-https"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "52.232.74.60"
    destination_address_prefix = "*"
  }
}

# Associate network security group with private subnet.
resource "azurerm_subnet_network_security_group_association" "private_subnet_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                          = "${var.prefix}-vm"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  network_interface_ids         = ["${azurerm_network_interface.nic.id}"]
  vm_size                       = var.vm_size
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  storage_os_disk {
    name              = "${var.prefix}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name  = "vault"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}