resource "aci_contract" "rs_prov_contract" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "rs_prov_contract"
  description = "This contract is created by terraform ACI provider"
  scope       = "tenant"
  target_dscp = "VA"
  prio        = "unspecified"
}

resource "aci_contract" "rs_cons_contract" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "rs_cons_contract"
  description = "This contract is created by terraform ACI provider"
  scope       = "tenant"
  target_dscp = "VA"
  prio        = "unspecified"
}

resource "aci_contract" "intra_epg_contract" {
  tenant_dn   = aci_tenant.tenant.id
  name        = "intra_epg_contract"
  description = "This contract is created by terraform ACI provider"
  scope       = "tenant"
  target_dscp = "VA"
  prio        = "unspecified"
}

resource "aci_imported_contract" "imported_contract" {
  tenant_dn = aci_tenant.tenant.id
  name      = "imported_contract"
}

resource "aci_taboo_contract" "taboo_contract" {
  tenant_dn = aci_tenant.tenant.id
  name      = "testcon"
}
