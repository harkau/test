provider "azurerm" {
   features {}
}
locals {
  ssh_publickey_path = "${path.module}/${var.ssh_publickey_file_name}"
}

resource "azurerm_resource_group" "RG_Name" {
  name     = var.RG_Name
  location = var.location
}

resource "azurerm_virtual_network" "VNet" {
  name                = var.VNet_Name
  location            = azurerm_resource_group.RG_Name.location
  resource_group_name = azurerm_resource_group.RG_Name.name
  address_space       = [var.AddressSpace]
}

resource "azurerm_subnet" "Subnet" {
  name                = "Subnet1"
  address_prefix       = var.AddressSpace
  resource_group_name  = azurerm_resource_group.RG_Name.name
  virtual_network_name = azurerm_virtual_network.VNet.name
}

resource "azurerm_public_ip" "pip" {
  name                = "pip_eastus"
  location            = azurerm_resource_group.RG_Name.location
  resource_group_name = azurerm_resource_group.RG_Name.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.VM["name"]}-nic"
  location            = azurerm_resource_group.RG_Name.location
  resource_group_name = azurerm_resource_group.RG_Name.name

  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = azurerm_subnet.Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_virtual_machine" "VM" {
  name                  = var.VM["name"]
  location              = azurerm_resource_group.RG_Name.location
  resource_group_name   = azurerm_resource_group.RG_Name.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
        name              = "${var.VM["name"]}-OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = var.VM["name"]
        admin_username = var.VM["username"]
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.VM["username"]}/.ssh/authorized_keys"
            key_data = file(local.ssh_publickey_path)
        }
    }
}

