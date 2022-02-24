variable "location" {
  type        = string
  description = "The Azure region to put the storage account into"
  default     = "westeurope"
}

variable env {
  type        = string
  description = "description"
}

variable shortenv {
  type        = string
  description = "description"
}

variable "site_domain" {
  type        = string
  description = "The domain name to use for the static site"
}

variable cloudflare_email {
  type        = string
  description = "description"
}

variable cloudflare_api_key {
  type        = string
  description = "description"
}
