resource "aci_match_rule" "rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule"
}

resource "aci_match_rule" "rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule2"
}

resource "aci_match_rule" "rule3" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule3"
}
