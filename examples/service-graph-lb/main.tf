terraform {
    required_providers {
        aci = {
            source = "ciscodevnet/aci"
            version = "0.6.0"
        }
    }
}

#Configure provider with your cisco aci credentials.
provider "aci" {
    username = var.aci_username
    password = var.aci_password
    url      = var.aci_url
    insecure = true
}

// Deploy the ACI configuration
module "service-graph-lb" {
//   source  = "app.terraform.io/cisco-dcn-ecosystem/demo_template/mso"
    source = "../../service-graph-lb"
//   version = "0.0.4"
    vmm_domain_name = "My-vCenter"
    vmm_controller_name = "dCloud-DC"
}

output "internal_vlan" {
    value = module.service-graph-lb.internal_vlan
    description = "The encap for the provider/internal arm"
}

output "external_vlan" {
    value = module.service-graph-lb.external_vlan
    description = "The encap for the consumer/external arm"
}
