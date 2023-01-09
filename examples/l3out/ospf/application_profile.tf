resource "aci_application_profile" "app_profile_for_epg" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "App_Web"
  description = "This application profile is created by the terraform ACI provider"
}
