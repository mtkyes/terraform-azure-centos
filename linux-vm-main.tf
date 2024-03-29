###########################
## Azure Linux VM - Main ##
###########################
locals{
  base-name = "${var.app_name}-linux-${random_string.linux-vm-name.result}"
}
# Generate random password
resource "random_password" "linux-vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}

# Generate a random vm name
resource "random_string" "linux-vm-name" {
  length  = 4
  upper   = false
  number  = false
  lower   = true
  special = false
}

# Create Security Group to access linux
resource "azurerm_network_security_group" "linux-vm-nsg" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${local.base-name}-nsg"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name

  security_rule {
    name                       = "AllowHTTP"
    description                = "Allow HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowSoftEther"
    description                = "Allow Soft Ether"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5555"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = {
    environment = var.environment
  }
}

# Associate the linux NSG with the subnet
resource "azurerm_subnet_network_security_group_association" "linux-vm-nsg-association" {
  depends_on=[azurerm_resource_group.network-rg]

  subnet_id                 = azurerm_subnet.network-subnet.id
  network_security_group_id = azurerm_network_security_group.linux-vm-nsg.id
}

# Get a Static Public IP
resource "azurerm_public_ip" "linux-vm-ip" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${local.base-name}-ip"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  allocation_method   = "Static"
  
  tags = { 
    environment = var.environment
  }
}

# Create Network Card for linux VM
resource "azurerm_network_interface" "linux-vm-nic" {
  depends_on=[azurerm_resource_group.network-rg]

  name                = "${local.base-name}-nic"
  location            = azurerm_resource_group.network-rg.location
  resource_group_name = azurerm_resource_group.network-rg.name
  enable_accelerated_networking = true
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.network-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux-vm-ip.id
    
  }

  tags = { 
    environment = var.environment
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "linux-vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Linux VM with linux server
resource "azurerm_linux_virtual_machine" "linux-vm" {
  depends_on=[azurerm_network_interface.linux-vm-nic]

  location              = azurerm_resource_group.network-rg.location
  resource_group_name   = azurerm_resource_group.network-rg.name
  name                  = "${local.base-name}-vm"
  network_interface_ids = [azurerm_network_interface.linux-vm-nic.id]
  size                  = var.linux_vm_size
 

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.centos_8_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${local.base-name}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "linux-${random_string.linux-vm-name.result}-vm"
  admin_username = var.linux_admin_username
  admin_password = random_password.linux-vm-password.result
  disable_password_authentication = false
  custom_data    = base64encode(data.template_file.linux-vm-cloud-init.rendered)
   admin_ssh_key {
     username   = var.linux_admin_username
     public_key = tls_private_key.linux-vm.public_key_openssh
   }
  
  tags = {
    environment = var.environment
  }
}

# Template for bootstrapping
data "template_file" "linux-vm-cloud-init" {
  template = file("azure-user-data.sh")
}
