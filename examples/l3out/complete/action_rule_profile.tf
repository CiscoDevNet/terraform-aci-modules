resource "aci_action_rule_profile" "set_rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule1"
}

resource "aci_action_rule_profile" "set_rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule2"
}
