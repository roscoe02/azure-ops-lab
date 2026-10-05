terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.0" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  storage_use_azuread = true # manage blob containers with Entra ID, not storage keys

  # Register only the Azure services this project uses (the default list is much longer)
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Compute",
    "Microsoft.Network",
    "Microsoft.Storage",
    "Microsoft.Insights",
    "Microsoft.Consumption",
  ]
}

# Reads CLOUDFLARE_API_TOKEN from the environment (stored in the macOS Keychain, never in a file).
# The token can only edit DNS for ethanroscoe.com.
provider "cloudflare" {}
