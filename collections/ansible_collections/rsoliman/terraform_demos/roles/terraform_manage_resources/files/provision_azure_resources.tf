variable "location_name" {
  type        = string
  description = "The Azure location to provision resources into."
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group Name to provision resources into."
}

variable "name_tag" {
  type        = string
  description = "The Name that will be used to tag Azure resources created by the TF plan."
  default     = "TFDemo"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type that will be used to create new EC2 instances."
  default     = "Standard_DS1_v2"
}

variable "image_publisher" {
  type        = string
  description = "The Publisher of the VM image."
  default     = "Canonical"
}

variable "image_offer" {
  type        = string
  description = "The Offer of the VM image."
  default     = "UbuntuServer"
}

variable "image_sku" {
  type        = string
  description = "The SKU of the VM image."
  default     = "18.04-LTS"
}

variable "image_version" {
  type        = string
  description = "The version of the VM image."
  default     = "latest"
}

variable "admin_username" {
  type        = string
  description = "The admin username."
  default     = "ansibleadmin"
}

variable "admin_password" {
  type        = string
  description = "The admin passwor"
}

variable "private_ip_address" {
  type        = string
  description = "The Private IP Addr of the VM"
  default     = "10.0.1.100"
}

provider "azurerm" {
    version = "~>2.46.0"
    features {}
}



# resource "azurerm_resource_group" "TFDemoRG" {
#    name     = "${var.name_tag}-RG"
#    location = var.location_name
#
#    tags = {
#        environment = "${var.name_tag}"
#    }
# }

resource "azurerm_virtual_network" "TFDemoNetwork" {
    name                = "${var.name_tag}-VNet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${var.resource_group_name}"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_subnet" "TFDemoSubnet" {
    name                 = "${var.name_tag}-Subnet"
    resource_group_name  = "${var.resource_group_name}"
    virtual_network_name = azurerm_virtual_network.TFDemoNetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "TFDemoPublicIP" {
    name                         = "${var.name_tag}-PublicIP"
    location                     = var.location_name
    resource_group_name          = "${var.resource_group_name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "${var.name_tag}"
    }
}


resource "azurerm_network_security_group" "TFDemoSG" {
    name                = "${var.name_tag}-SG"
    location            = var.location_name
    resource_group_name = "${var.resource_group_name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "${var.name_tag}"
    }
}

# Create network interface
resource "azurerm_network_interface" "TFDemoNIC" {
    name                      = "${var.name_tag}-NIC"
    location                  = var.location_name
    resource_group_name       = "${var.resource_group_name}"

    ip_configuration {
        name                          = "TFDemoNicConfiguration"
        subnet_id                     = azurerm_subnet.TFDemoSubnet.id
        private_ip_address_allocation = "Static"
        private_ip_address            = var.private_ip_address
        public_ip_address_id          = azurerm_public_ip.TFDemoPublicIP.id
    }

    tags = {
        environment = "${var.name_tag}"
    }
}


resource "azurerm_network_interface_security_group_association" "TFDemo_Association" {
    network_interface_id      = azurerm_network_interface.TFDemoNIC.id
    network_security_group_id = azurerm_network_security_group.TFDemoSG.id
}


resource "azurerm_linux_virtual_machine" "TFDemoVM" {
    name                  = "${var.name_tag}-VM"
    location              = var.location_name
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = [azurerm_network_interface.TFDemoNIC.id]
    size                  = var.instance_type


    os_disk {
        name              = "TFDemoOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = var.image_publisher 
        offer     = var.image_offer
        sku       = var.image_sku
        version   = var.image_version
    }

    computer_name  = "${var.name_tag}-VM"
    admin_username = var.admin_username
    admin_password = var.admin_password
    disable_password_authentication = false
      
    tags = {
        environment = "${var.name_tag}"
    }
}