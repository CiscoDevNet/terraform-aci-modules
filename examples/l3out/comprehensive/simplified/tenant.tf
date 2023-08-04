# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "module_l3out_tf_tenant_dynamic"
  description = "Created for l3out module"
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

resource "aci_ospf_interface_policy" "ospf_interface_policy2" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "simplified_ospfpol2"
  cost         = "unspecified"
  ctrl         = ["mtu-ignore"]
  dead_intvl   = "40"
  hello_intvl  = "10"
  nw_t         = "bcast"
  pfx_suppress = "inherit"
  prio         = "1"
  rexmit_intvl = "5"
  xmit_delay   = "1"
}

resource "aci_ospf_interface_policy" "ospf_interface_policy3" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "simplified_ospfpol3"
  cost         = "unspecified"
  ctrl         = ["mtu-ignore"]
  dead_intvl   = "40"
  hello_intvl  = "10"
  nw_t         = "bcast"
  pfx_suppress = "inherit"
  prio         = "1"
  rexmit_intvl = "5"
  xmit_delay   = "1"
}

resource "aci_ospf_interface_policy" "ospf_interface_policy4" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "simplified_ospfpol4"
  cost         = "unspecified"
  ctrl         = ["mtu-ignore"]
  dead_intvl   = "40"
  hello_intvl  = "10"
  nw_t         = "bcast"
  pfx_suppress = "inherit"
  prio         = "1"
  rexmit_intvl = "5"
  xmit_delay   = "1"
}