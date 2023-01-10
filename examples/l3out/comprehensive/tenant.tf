# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "module_l3out_tf_tenant"
  description = "Created for l3out module"
}
