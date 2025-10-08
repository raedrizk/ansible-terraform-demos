terraform {
	backend "remote" {
    organization = "<TF_ORG>" 

    workspaces { 
      name = "<TF_WORKSPACE>" 
    } 
	}

   required_providers {
    aap = {
      source = "ansible/aap"
    }
  }
  
}

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

variable "public_key" {
  type        = string
  description = "The public key to deploy for the new instance(s)."
}

variable "admin_username" {
  type        = string
  description = "The VM admin username, also associated with the public key."
  default     = "ansibleadmin"
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

variable "aap_host" {
  type        = string
  description = "The AAP host URL."
}

variable "aap_username" {
  type        = string
  description = "The AAP username."
}

variable "aap_password" {
  type        = string
  description = "The AAP password."
  sensitive   = true
}

provider "azurerm" {
    features {}
}

provider "aap" {
  host                 = var.aap_host
  username             = var.aap_username
  password             = var.aap_password
  insecure_skip_verify = false
}

resource "azurerm_virtual_network" "TFDemoNetwork" {
    name                = "${var.name_tag}-VNet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location_name
    resource_group_name = var.resource_group_name

    tags = {
        environment = var.name_tag
    }
}

resource "azurerm_subnet" "TFDemoSubnet" {
    name                 = "${var.name_tag}-Subnet"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.TFDemoNetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "TFDemoPublicIP" {
    name                         = "${var.name_tag}-PublicIP"
    location                     = var.location_name
    resource_group_name          = var.resource_group_name
    allocation_method            = "Static"
    sku                          = "Standard"

    tags = {
        environment = var.name_tag
    }
}


resource "azurerm_network_security_group" "TFDemoSG" {
    name                = "${var.name_tag}-SG"
    location            = var.location_name
    resource_group_name = var.resource_group_name

    security_rule {
        name                       = "AllowSSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowHTTP"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "AllowHTTPS"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = var.name_tag
    }
}

# Create network interface
resource "azurerm_network_interface" "TFDemoNIC" {
    name                      = "${var.name_tag}-NIC"
    location                  = var.location_name
    resource_group_name       = var.resource_group_name

    ip_configuration {
        name                          = "TFDemoNicConfiguration"
        subnet_id                     = azurerm_subnet.TFDemoSubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.TFDemoPublicIP.id
    }

    tags = {
        environment = var.name_tag
    }
}

resource "azurerm_network_interface_security_group_association" "TFDemo_Association" {
    network_interface_id      = azurerm_network_interface.TFDemoNIC.id
    network_security_group_id = azurerm_network_security_group.TFDemoSG.id
}

resource "azurerm_ssh_public_key" "TFDemo_Key" {
    name                = "${var.name_tag}-public-key"
    resource_group_name = var.resource_group_name
    location            = var.location_name
    public_key          = var.public_key
}

resource "azurerm_linux_virtual_machine" "TFDemoVM" {
    name                  = "${var.name_tag}-VM"
    location              = var.location_name
    resource_group_name   = var.resource_group_name
    network_interface_ids = [azurerm_network_interface.TFDemoNIC.id]
    size                  = var.instance_type

    os_disk {
        name              = "${var.name_tag}-Disk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = var.image_publisher 
        offer     = var.image_offer
        sku       = var.image_sku
        version   = var.image_version
    }
    admin_username = var.admin_username
    computer_name  = "${var.name_tag}-VM"
    admin_ssh_key {
        username   = var.admin_username
        public_key = azurerm_ssh_public_key.TFDemo_Key.public_key
    }
      
    tags = {
        environment = var.name_tag
    }
}

resource "aap_inventory" "tf_inventory" {
  name        = "AUTO_TF_Inventory"
  description = "Inventory created by Terraform AAP provider"  
}

resource "aap_group" "tf_group" {
  inventory_id = aap_inventory.tf_inventory.id
  name         = "TFHosts"
}

resource "aap_host" "tf_host" {
  inventory_id = aap_inventory.tf_inventory.id
  name         = "${var.name_tag}-VM"
  variables = jsonencode(
    {
      "ansible_user" : var.admin_username
      "ansible_host" : azurerm_linux_virtual_machine.TFDemoVM.public_ip_address
    }
  )
  groups = [aap_group.tf_group.id]
}

resource "aap_job" "tf_job" {
  job_template_id = 112 # Replace with your actual job template ID
  inventory_id    = aap_inventory.tf_inventory.id

  # This resource creation needs to wait for the host and group to be created in the inventory
  depends_on = [
    aap_inventory.tf_inventory,
    aap_group.tf_group,
    aap_host.tf_host
  ]
}

output "instance_ip_addr" {
  value       = azurerm_linux_virtual_machine.TFDemoVM.public_ip_address
  description = "The Public IP address of the instance."
}

output "instance_id" {
  value       = azurerm_linux_virtual_machine.TFDemoVM.id
  description = "The ID of the instance."
}
