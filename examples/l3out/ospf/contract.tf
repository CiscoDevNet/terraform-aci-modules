resource "aci_contract" "contract" {
  tenant_dn = aci_tenant.tenant.id
  name      = "For_Internet"
}
