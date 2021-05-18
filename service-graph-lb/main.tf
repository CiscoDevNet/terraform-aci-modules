terraform {
    required_providers {
        aci = {
            source = "ciscodevnet/aci"
        }
    }
}

# Define an ACI Tenant Resource.
resource "aci_tenant" "this" {
    name        = var.tenant.name
    description = var.tenant.description
}
