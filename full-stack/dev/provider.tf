######################################################################
# Provider 設定
######################################################################

# Terraformに関する設定
terraform {

  # Providerバージョンを設定
  required_providers {

    # AWS Providerバージョンを設定
    aws      = "4.12.1"

    # Template Providerバージョンを設定
    template = "2.2.0"
  }
}
