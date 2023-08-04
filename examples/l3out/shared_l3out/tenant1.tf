# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant1" {
  name        = "TF_tenant1"
  description = "Created for l3out module"
}

resource "aci_application_profile" "app_profile_for_epg1" {
  tenant_dn   = aci_tenant.tenant1.id
  name        = "App"
  description = "This application profile is created by the terraform ACI provider"
}

resource "aci_application_epg" "Web_epg1" {
  application_profile_dn = aci_application_profile.app_profile_for_epg1.id
  name                   = "EPG"
  relation_fv_rs_bd      = aci_bridge_domain.bridge_domain1.id
  relation_fv_rs_cons    = [aci_contract.contract1.id]
}

resource "aci_bridge_domain" "bridge_domain1" {
  tenant_dn   = aci_tenant.tenant1.id
  name        = "BD"
  description = "This bridge domain is created by terraform ACI provider"
}

resource "aci_subnet" "bd_subnet1" {
  parent_dn = aci_bridge_domain.bridge_domain1.id
  ip        = "10.1.1.1/24"
  scope     = ["public", "shared"]
}

resource "aci_vrf" "vrf1" {
  tenant_dn = aci_tenant.tenant1.id
  name      = "VRF"
}
