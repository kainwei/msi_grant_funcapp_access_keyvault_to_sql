variable "storage_account_spec" {
  description = "map of key-values for the storage account object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "service_plan_spec" {
  description = "map of key-values for the service plan object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "function_app_spec" {
  description = "map of key-values for the function app object. See main.tf for valid keys"
  type        = map
  default     = {}
}

variable "tenant_id" {
  default = "9ff41cc1-b5be-4a5e-8b1e-cea44886ca5a"
}