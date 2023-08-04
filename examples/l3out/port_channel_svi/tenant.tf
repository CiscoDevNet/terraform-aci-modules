# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "TF_tenant"
  description = "Created for l3out module"
}

resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf"
}

resource "aci_l3_domain_profile" "profile" {
  name = "l3_domain"
}
