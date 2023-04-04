resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf1"
}

resource "aci_vrf" "vrf2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf2"
}

resource "aci_vrf" "vrf3" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf3"
}

resource "aci_vrf" "vrf4" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf4"
}

resource "aci_vrf" "vrf5" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf5"
}

resource "aci_vrf" "vrf6" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf6"
}
