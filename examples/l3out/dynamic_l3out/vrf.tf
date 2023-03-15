resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf1"
}
