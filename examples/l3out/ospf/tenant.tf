# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "TF_tenant"
  description = "Created for l3out module"
}

resource "aci_application_profile" "app_profile_for_epg" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "App_Web"
  description = "This application profile is created by the terraform ACI provider"
}

resource "aci_application_epg" "Web_epg" {
  application_profile_dn = aci_application_profile.app_profile_for_epg.id
  name                   = "Web_epg"
  relation_fv_rs_bd      = aci_bridge_domain.bridge_domain.id
  relation_fv_rs_cons    = [aci_contract.contract.id]
}

resource "aci_bridge_domain" "bridge_domain" {
  tenant_dn                = aci_tenant.tenant.id
  name                     = "bd_for_subnet"
  description              = "This bridge domain is created by terraform ACI provider"
  relation_fv_rs_bd_to_out = [module.l3out.l3out_dn]
}

resource "aci_subnet" "bd_subnet" {
  parent_dn = aci_bridge_domain.bridge_domain.id
  ip        = "1.1.1.1/24"
  scope     = ["public"]
}

resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "App_vrf"
}

resource "aci_l3_domain_profile" "profile" {
  name = "l3_domain"
}

resource "aci_ospf_interface_policy" "ospf_interface_policy" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "demo_ospfpol"
  cost         = "unspecified"
  ctrl         = ["mtu-ignore"]
  dead_intvl   = "40"
  hello_intvl  = "10"
  nw_t         = "p2p"
  pfx_suppress = "inherit"
  prio         = "1"
  rexmit_intvl = "5"
  xmit_delay   = "1"
}
