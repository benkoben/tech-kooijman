locals {
  custom_hostname_prefixes = ["tech", "www.tech"]
}

resource azurerm_resource_group "staticcontent" {
    name     = "ben-${var.env}-svc-staticweb" 
    location = var.location
}

resource "azurerm_cdn_profile" "staticcontent" {
  name                = "static-cdn-profile01-${var.shortenv}"
  location            = azurerm_resource_group.staticcontent.location
  resource_group_name = azurerm_resource_group.staticcontent.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "staticcontent" {
  name                = "static-cdn-endpoint01-${var.shortenv}"
  profile_name        = azurerm_cdn_profile.staticcontent.name
  location            = azurerm_resource_group.staticcontent.location
  resource_group_name = azurerm_resource_group.staticcontent.name
  is_http_allowed     = false
  is_https_allowed    = true

  origin_host_header = azurerm_storage_account.staticcontent.primary_web_host

  origin {
    name      = split(".", azurerm_storage_account.staticcontent.primary_web_host)[0]
    host_name = azurerm_storage_account.staticcontent.primary_web_host
  }
}

resource "azurerm_storage_account" "staticcontent" {
  name                      = "bensvcsaccstaticweb01${var.shortenv}"
  resource_group_name       = azurerm_resource_group.staticcontent.name
  location                  = azurerm_resource_group.staticcontent.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = false

  network_rules {
    default_action = "Deny"
    bypass = ["AzureServices"]
  }

  custom_domain {
    name = "tech.${var.site_domain}"
    use_subdomain = true
  }

  static_website {
    index_document = "index.html"
  }

  tags = {
    environment = "live"
  }

}

resource "null_resource" "uploadfile" {    
  triggers = {
      homepage = sha256(file("../content/out/index.html"))
    }

  provisioner "local-exec" {
    command = "az storage blob upload-batch --source '../content/out/' --destination '$web' --account-name ${azurerm_storage_account.staticcontent.name}"
    interpreter = ["bash", "-c"]
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name = var.site_domain
  }
}

resource "cloudflare_record" "sites" {
  for_each = toset(local.custom_hostname_prefixes)

  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "${each.value}.${var.site_domain}"
  value   = "${azurerm_cdn_endpoint.staticcontent.name}.azureedge.net"
  type    = "CNAME"

  ttl     = 1
  proxied = false
}


# set custom hostname on cdn endpoint and enable 
# microsoft managed SSL
resource "null_resource" "add_custom_domain" {
  for_each  = toset(local.custom_hostname_prefixes)

  depends_on = [
    azurerm_cdn_endpoint.staticcontent,
    cloudflare_record.sites
  ]

  provisioner "local-exec" {
    command = "az cdn custom-domain create --profile-name $PROFILE_NAME --endpoint-name $ENDPOINT_NAME --hostname $CUSTOM_DOMAIN --name $CST_PRFL_NAME --resource-group $RG_NAME && az cdn custom-domain enable-https --profile-name $PROFILE_NAME --endpoint-name $ENDPOINT_NAME --name $CST_PRFL_NAME --resource-group $RG_NAME"
    interpreter = ["bash", "-c"]
    environment = {
      CUSTOM_DOMAIN = "${each.value}.${var.site_domain}"
      CST_PRFL_NAME = replace(each.value, ".", "")
      RG_NAME       = azurerm_resource_group.staticcontent.name
      ENDPOINT_NAME = azurerm_cdn_endpoint.staticcontent.name
      PROFILE_NAME  = azurerm_cdn_profile.staticcontent.name
    }
  }
}