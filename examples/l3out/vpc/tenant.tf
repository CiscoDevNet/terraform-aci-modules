# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "TF_tenant_vpc"
  description = "Created for l3out module"
}

resource "aci_contract" "contract" {
  tenant_dn = aci_tenant.tenant.id
  name      = "For_Internet"
}

resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "App_vrf"
}

resource "aci_vrf" "vrf2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "App_vrf2"
}

resource "aci_ospf_interface_policy" "ospf_interface_policy" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "simplified_ospfpol"
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
