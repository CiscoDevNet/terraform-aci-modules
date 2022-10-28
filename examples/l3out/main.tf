terraform {
  required_providers {
    aci = {
      source = "ciscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = ""
  password = ""
  url      = ""
  insecure = true
}

# Define an ACI Tenant Resource.
resource "aci_tenant" "tenant" {
  name        = "module_l3out_tf_tenant"
  description = "Created for l3out module"
}

module "l3out" {
  source                         = "./l3out"
  tenant_dn                      = aci_tenant.tenant.id
  name                           = "module_l3out"
  alias                          = "l3out"
  description                    = "Created by l3out module"
  route_control_enforcement      = true
  target_dscp                    = "EF"
  vrf_dn                         = "uni/tn-vEPC/ctx-VRF"
  l3_domain_dn                   = "uni/l3dom-ansible_l3_dom"
  route_profile_for_interleak_dn = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
  route_control_for_dampening = {
    address_family = "ipv4"
    route_map_dn   = "uni/tn-vEPC/prof-route-map-nso-prefix-routing"
  }
  l3out_external_epg = [{ # remove l3out title
    name                   = "ext_epg1"
    description            = "l3out_ext_epg1"
    flood_on_encap         = "enabled"
    label_match_criteria   = "All"
    preferred_group_member = true
    qos_class              = "level1"
    target_dscp            = "VA"
    subnets =[
        {
            ip = "10.0.1.0/24"
            scope = ["import-rtctrl", "export-rtctrl"]
            aggregate = "shared-rtctrl"

        },
        {
            ip = "11.0.1.0/24"
            scope = ["import-rtctrl", "export-rtctrl"]
            aggregate = "none"

        },
    ]
  },
  {
    name                   = "ext_epg2"
    description            = "l3out_ext_epg2"
    flood_on_encap         = "enabled"
    label_match_criteria   = "All"
    preferred_group_member = false
    qos_class              = "level2"
    target_dscp            = "CS5"
  },
  {
    name                   = "ext_epg3"
    description            = "l3out_ext_epg3"
    flood_on_encap         = "disabled"
    label_match_criteria   = "All"
    preferred_group_member = true
    qos_class              = "level3"
    target_dscp            = "CS4"
    subnets =[
        {
            ip = "21.1.1.0/24"
            scope = ["import-rtctrl", "export-rtctrl"]
            aggregate = "shared-rtctrl"

        },
        {
            ip = "33.1.1.0/24"
            scope = ["import-rtctrl", "export-rtctrl"]
            aggregate = "none"

        },
    ]
  }]
}