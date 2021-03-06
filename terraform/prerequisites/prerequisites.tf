resource "azurerm_resource_group" "jmeter_acr_rg" {
  name     = var.JMETER_ACR_RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_container_registry" "jmeter_acr" {
  name                = var.JMETER_ACR_NAME
  resource_group_name = var.JMETER_ACR_RESOURCE_GROUP_NAME
  location = var.LOCATION
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_resource_group" "vnet_rg" {
  name     = var.VNET_RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_virtual_network" "jmeter_vnet" {
  name                = var.VNET_NAME
  location            = azurerm_resource_group.vnet_rg.location
  resource_group_name = azurerm_resource_group.vnet_rg.name
  address_space       = [var.VNET_ADDRESS_SPACE]
}

resource "azurerm_subnet" "jmeter_subnet" {
  name                 = var.SUBNET_NAME
  resource_group_name  = azurerm_resource_group.vnet_rg.name
  virtual_network_name = azurerm_virtual_network.jmeter_vnet.name
  address_prefixes     = [var.SUBNET_ADDRESS_PREFIX]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_resource_group" "storage_rg" {
  name     = var.JMETER_STORAGE_ACCOUNT_RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_storage_account" "jmeter_storage" {
  name                = var.JMETER_STORAGE_ACCOUNT_NAME
  resource_group_name = azurerm_resource_group.storage_rg.name
  location            = azurerm_resource_group.storage_rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Allow"
    virtual_network_subnet_ids = [azurerm_subnet.jmeter_subnet.id]
  }
}

resource "azurerm_storage_share" "jmeter_share" {
  name                 = "jmeter"
  storage_account_name = azurerm_storage_account.jmeter_storage.name
  quota                = var.JMETER_STORAGE_QUOTA_GIGABYTES
}

