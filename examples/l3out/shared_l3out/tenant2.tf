# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant2" {
  name        = "TF_tenant2"
  description = "Created for l3out module"
}

resource "aci_application_profile" "app_profile_for_epg2" {
  tenant_dn   = aci_tenant.tenant2.id
  name        = "App"
  description = "This application profile is created by the terraform ACI provider"
}

resource "aci_application_epg" "Web_epg2" {
  application_profile_dn = aci_application_profile.app_profile_for_epg2.id
  name                   = "EPG"
  relation_fv_rs_bd      = aci_bridge_domain.bridge_domain2.id
  relation_fv_rs_cons    = [aci_contract.contract1.id]
}

resource "aci_bridge_domain" "bridge_domain2" {
  tenant_dn   = aci_tenant.tenant2.id
  name        = "BD"
  description = "This bridge domain is created by terraform ACI provider"
}

resource "aci_subnet" "bd_subnet2" {
  parent_dn = aci_bridge_domain.bridge_domain2.id
  ip        = "10.2.2.1/24"
  scope     = ["public", "shared"]
}

resource "aci_vrf" "vrf2" {
  tenant_dn = aci_tenant.tenant2.id
  name      = "VRF"
}
