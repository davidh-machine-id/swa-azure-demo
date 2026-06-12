# ============================================================
# Azure SWA Demo Environment
# ============================================================

module "azure_swa" {
  source = "../../modules/azure"

  prefix              = var.prefix
  location            = var.location
  resource_group_name = var.resource_group_name

  # SWA Configuration (optional - leave empty if not ready)
  swa_oidc_issuer_url = var.swa_oidc_issuer_url
  spiffe_subject      = var.spiffe_subject
  azure_jwt_audience  = var.azure_jwt_audience
}
