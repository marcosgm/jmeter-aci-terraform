variable "RESOURCE_GROUP_NAME" {
  type    = string
  default = "loadtest-aci-rg"
}

variable "LOCATION" {
  type    = string
  default = "eastus"
}

variable "PREFIX" {
  type    = string
  default = "jmeter"
}
variable "VNET_RESOURCE_GROUP_NAME" {
  type    = string
  default = "loadtest-vnet-rg"
}

variable "VNET_ADDRESS_SPACE" {
  type    = string
  default = "10.2.0.0/16"
}

variable "SUBNET_ADDRESS_PREFIX" {
  type    = string
  default = "10.2.0.0/24"
}

variable "VNET_NAME" {
  type    = string
  default = "loadtest-vnet"
}

variable "SUBNET_NAME" {
  type    = string
  default = "aci-subnet"
}

variable "JMETER_WORKERS_COUNT" {
  type    = number
  default = 1
}

variable "JMETER_WORKER_CPU" {
  type    = string
  default = "2.0"
}

variable "JMETER_WORKER_MEMORY" {
  type    = string
  default = "8.0"
}

variable "JMETER_CONTROLLER_CPU" {
  type    = string
  default = "2.0"
}

variable "JMETER_CONTROLLER_MEMORY" {
  type    = string
  default = "8.0"
}

variable "JMETER_DOCKER_IMAGE" {
  type    = string
  default = "justb4/jmeter:5.3"
}

variable "JMETER_DOCKER_PORT" {
  type    = number
  default = 1099
}

variable "JMETER_ACR_NAME" {
  type    = string
  default = "loadtestacr"
}

variable "JMETER_ACR_RESOURCE_GROUP_NAME" {
  type    = string
  default = "loadtest-infra-rg"
}

variable "JMETER_STORAGE_ACCOUNT_NAME" {
  type    = string
  default = "jmeterresults23143"
}

variable "JMETER_STORAGE_ACCOUNT_RESOURCE_GROUP_NAME" {
  type    = string
  default = "loadtest-infra-rg"
}

variable "JMETER_STORAGE_QUOTA_GIGABYTES" {
  type    = number
  default = 1
}

variable "JMETER_JMX_FILE" {
  type        = string
  description = "JMX file"
  default = "sample.jmx"
}

variable "JMETER_RESULTS_FILE" {
  type    = string
  default = "results.jtl"
}

variable "JMETER_DASHBOARD_FOLDER" {
  type    = string
  default = "dashboard"
}

variable "JMETER_EXTRA_CLI_ARGUMENTS" {
  type    = string
  default = ""
}
