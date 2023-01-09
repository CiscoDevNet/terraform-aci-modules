resource "aci_application_profile" "app_profile_for_epg" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "ap_for_epg"
  description = "This app profile is created by terraform ACI providers"
}
