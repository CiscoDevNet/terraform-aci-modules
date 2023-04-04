# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "module_l3out_tf_tenant"
  description = "Created for l3out module"
}

resource "aci_l3_outside" "l3out" {
  tenant_dn              = aci_tenant.tenant.id
  name                   = "l3out_tf"
  relation_l3ext_rs_ectx = aci_vrf.vrf.id
}

resource "aci_external_network_instance_profile" "l3out_external_epgs" {
  l3_outside_dn          = aci_l3_outside.l3out.id
  name                   = "tf_ext_epg"
  relation_fv_rs_cons_if = [aci_imported_contract.imported_contract2.id]
}