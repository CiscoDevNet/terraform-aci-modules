# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "TF_tenant"
  description = "Created for l3out module"
}
