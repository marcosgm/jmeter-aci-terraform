data "azurerm_container_registry" "jmeter_acr" {
  name                = var.JMETER_ACR_NAME
  resource_group_name = var.JMETER_ACR_RESOURCE_GROUP_NAME
}

data "azurerm_virtual_network" "jmeter_vnet" {
  name                = var.VNET_NAME
  resource_group_name = var.VNET_RESOURCE_GROUP_NAME
}

data "azurerm_subnet" "jmeter_subnet" {
  name                 = var.SUBNET_NAME
  resource_group_name  = data.azurerm_virtual_network.jmeter_vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.jmeter_vnet.name
  
  #ensure the subnet has service delegation
  #  service_delegation {
  #    name    = "Microsoft.ContainerInstance/containerGroups"
  #    actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
  
  #and also
  #  service_endpoints = ["Microsoft.Storage"]
}

data "azurerm_storage_account" "jmeter_storage" {
  name                = var.JMETER_STORAGE_ACCOUNT_NAME
  resource_group_name = var.JMETER_STORAGE_ACCOUNT_RESOURCE_GROUP_NAME
  
  #ensure the storage account has 
  #network_rules {
  #  default_action             = "Allow"
  #  virtual_network_subnet_ids = ["azurerm_subnet.jmeter_subnet.id"]
  
}
# this is not yet supported in terraform: 
#data "azurerm_storage_share" "jmeter_share" {
#  name                 = "jmeter"
#  storage_account_name = data.azurerm_storage_account.jmeter_storage.name
#}


resource "azurerm_resource_group" "jmeter_rg" {
  name     = var.RESOURCE_GROUP_NAME
  location = var.LOCATION
}

resource "azurerm_network_profile" "jmeter_net_profile" {
  name                = "${var.PREFIX}netprofile"
  location            = azurerm_resource_group.jmeter_rg.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  container_network_interface {
    name = "${var.PREFIX}cnic"

    ip_configuration {
      name      = "${var.PREFIX}ipconfig"
      subnet_id = data.azurerm_subnet.jmeter_subnet.id
    }
  }
}

resource "azurerm_container_group" "jmeter_workers" {
  count               = var.JMETER_WORKERS_COUNT
  name                = "${var.PREFIX}-worker${count.index}"
  location            = azurerm_resource_group.jmeter_rg.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  ip_address_type = "private"
  os_type         = "Linux"

  network_profile_id = azurerm_network_profile.jmeter_net_profile.id
  depends_on = [
    azurerm_network_profile.jmeter_net_profile,
  ] #to allow proper destruction of the network profile, must destroy ACI first
  
  image_registry_credential {
    server   = data.azurerm_container_registry.jmeter_acr.login_server
    username = data.azurerm_container_registry.jmeter_acr.admin_username
    password = data.azurerm_container_registry.jmeter_acr.admin_password
  }

  container {
    name   = "jmeter"
    image  = var.JMETER_DOCKER_IMAGE
    cpu    = var.JMETER_WORKER_CPU
    memory = var.JMETER_WORKER_MEMORY

    ports {
      port     = var.JMETER_DOCKER_PORT
      protocol = "TCP"
    }

    volume {
      name                 = "jmeter"
      mount_path           = "/jmeter"
      read_only            = true
      storage_account_name = data.azurerm_storage_account.jmeter_storage.name
      storage_account_key  = data.azurerm_storage_account.jmeter_storage.primary_access_key
      share_name           = "jmeter"
    }

    commands = [
      "/bin/sh",
      "-c",
      "cp -r /jmeter/* .; /entrypoint.sh -s -J server.rmi.ssl.disable=true",
    ]
  }
}

resource "azurerm_container_group" "jmeter_controller" {
  name                = "${var.PREFIX}-controller"
  location            = azurerm_resource_group.jmeter_rg.location
  resource_group_name = azurerm_resource_group.jmeter_rg.name

  ip_address_type = "private"
  os_type         = "Linux"

  network_profile_id = azurerm_network_profile.jmeter_net_profile.id
  depends_on = [
    azurerm_network_profile.jmeter_net_profile,
  ] #to allow proper destruction of the network profile, must destroy ACI first

  restart_policy = "Never"

  image_registry_credential {
    server   = data.azurerm_container_registry.jmeter_acr.login_server
    username = data.azurerm_container_registry.jmeter_acr.admin_username
    password = data.azurerm_container_registry.jmeter_acr.admin_password
  }

  container {
    name   = "jmeter"
    image  = var.JMETER_DOCKER_IMAGE
    cpu    = var.JMETER_CONTROLLER_CPU
    memory = var.JMETER_CONTROLLER_MEMORY

    ports {
      port     = var.JMETER_DOCKER_PORT
      protocol = "TCP"
    }

    volume {
      name                 = "jmeter"
      mount_path           = "/jmeter"
      read_only            = false
      storage_account_name = data.azurerm_storage_account.jmeter_storage.name
      storage_account_key  = data.azurerm_storage_account.jmeter_storage.primary_access_key
      share_name           = "jmeter"
    }

    commands = [
      "/bin/sh",
      "-c",
      "cd /jmeter; /entrypoint.sh -n -J server.rmi.ssl.disable=true -t ${var.JMETER_JMX_FILE} -l ${var.JMETER_RESULTS_FILE} -e -o ${var.JMETER_DASHBOARD_FOLDER} -R ${join(",", azurerm_container_group.jmeter_workers.*.ip_address)} ${var.JMETER_EXTRA_CLI_ARGUMENTS}",
    ]
  }
}
