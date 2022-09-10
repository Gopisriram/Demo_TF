terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "f1731f45-9e6c-4edd-9111-941c269e8f43"
  client_id       = "6ff33b8e-5f9f-49dc-ab7b-c7f86bfc3f4b"
  tenant_id       = "541edfcc-823d-44ad-b4dd-3b00b0279605"
  client_secret   = "lF~8Q~4j-cofPCh5NnYWKLNoXXoHGUnN.OIJKb8q"

}

# Create a resource group
resource "azurerm_resource_group" "corp1" {
  name     = "${var.rgname}"
  location = "${var.rglocation}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "net1" {
  name                = "${var.prefix}-net1"
  resource_group_name = azurerm_resource_group.corp1.name
  location            = azurerm_resource_group.corp1.location
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "sub1" {
  name                 = "${var.prefix}-sub1"
  resource_group_name  = azurerm_resource_group.corp1.name
  virtual_network_name = azurerm_virtual_network.net1.name
  address_prefixes     = ["10.10.0.0/24"]
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.corp1.location
  resource_group_name = azurerm_resource_group.corp1.name

  security_rule {
    name                       = "rule1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc1" {
  subnet_id                 = azurerm_subnet.sub1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}
resource "azurerm_network_interface" "int1" {
  name                = "${var.prefix}-int"
  location            = azurerm_resource_group.corp1.location
  resource_group_name = azurerm_resource_group.corp1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub1.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "${var.prefix}-VM1"
  resource_group_name = azurerm_resource_group.corp1.name
  location            = azurerm_resource_group.corp1.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Password@123!"
  network_interface_ids = [
    azurerm_network_interface.int1.id,
  ]

 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}