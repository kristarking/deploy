terraform {
  required_providers {
      azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.3.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Create a Resource Group
resource "azurerm_resource_group" "KingRG" {
  name = "KingRG"
  location = " South Africa North"
}


# Create a Virtual Network
resource "azurerm_virtual_network" "KingVnet" {
  name                = "KingVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.KingRG.location
  resource_group_name = azurerm_resource_group.KingRG.name
}

# Create a Public Subnet
resource "azurerm_subnet" "KingSubnet" {
  name                 = "KingSubnet"
  resource_group_name  = azurerm_resource_group.KingRG.name
  virtual_network_name = azurerm_virtual_network.KingVnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "KingNSG" {
  name                = "KingNSG"
  location            = azurerm_resource_group.KingRG.location
  resource_group_name = azurerm_resource_group.KingRG.name
}

# Create NSG Rule for Port 22 (SSH)
resource "azurerm_network_security_rule" "SSH" {
  name                        = "Allow-SSH"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.KingNSG.name
  resource_group_name         = azurerm_resource_group.KingRG.name
}

# Create NSG Rule for Port 80 (HTTP)
resource "azurerm_network_security_rule" "HTTP" {
  name                        = "Allow-HTTP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.KingNSG.name
  resource_group_name         = azurerm_resource_group.KingRG.name
}

# Create a Public IP Address
resource "azurerm_public_ip" "King-ip" {
  name                = "King-ip"
  location            = azurerm_resource_group.KingRG.location
  resource_group_name = azurerm_resource_group.KingRG.name
  allocation_method   = "Static"
}

# Create a Network Interface (NIC)
resource "azurerm_network_interface" "KingNic" {
  name                = "KingNic"
  location            = azurerm_resource_group.KingRG.location
  resource_group_name = azurerm_resource_group.KingRG.name

 ip_configuration {
  name                          = "internal"
  subnet_id                     = azurerm_subnet.KingSubnet.id
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.0.1.4"  
  public_ip_address_id          = azurerm_public_ip.King-ip.id
}
}
# Connect NiC And NSG
resource "azurerm_network_interface_security_group_association" "KingCo" {
  network_interface_id      = azurerm_network_interface.KingNic.id
  network_security_group_id = azurerm_network_security_group.KingNSG.id
}

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "Kingvm" {
  name                  = "Kingvm"
  location              = azurerm_resource_group.KingRG.location
  resource_group_name   = azurerm_resource_group.KingRG.name
  size                  = "Standard_B1ls"
  admin_username        = "king"
  admin_password        = "Emmanuel2024!" 
  network_interface_ids = [azurerm_network_interface.KingNic.id]
  disable_password_authentication = true

  #SSH Public Key 
  admin_ssh_key {
    username   = "king"
    public_key = var.ssh_public_key
  }

  # OS Disk Configuration
  os_disk {
    name              = "KingOsDisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Source Image Reference (Ubuntu 22.04 LTS)
  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}
}

# Output the Public IP Address
output "public_ip_address" {
  description = "The public IP address of the virtual machine"
  value       = azurerm_public_ip.King-ip.ip_address
}