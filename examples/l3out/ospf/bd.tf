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
