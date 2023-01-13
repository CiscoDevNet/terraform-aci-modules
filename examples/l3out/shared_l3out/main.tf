terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = ""
  password = ""
  url      = ""
  insecure = true
}

data "aci_tenant" "common" {
  name  = "common"
}

data "aci_vrf" "default" {
  tenant_dn  = data.aci_tenant.common.id
  name       = "default"
}

resource "aci_l3_domain_profile" "profile" {
  name = "l3_WAN"
}

module "l3out" {
  source                    = "../l3out"
  tenant_dn                 = data.aci_tenant.common.id
  name                      = "WAN"
  alias                     = "l3out"
  description               = "Created by l3out module"
  route_control_enforcement = true
  vrf_dn                    = data.aci_vrf.default.id
  l3_domain_dn              = aci_l3_domain_profile.profile.id

  logical_node_profiles = [
    {
      name = "Node"
      nodes = [
        {
          node_id   = "102"
          pod_id    = "1"
          router_id = "101.101.101.101"
          static_routes = [
            {
              ip = "0.0.0.0/0"
              next_hop_addresses = [
                {
                  next_hop_ip = "221.221.221.1"
                }
              ]
            }
          ]
        }
      ]

      interfaces = [
        {
          name = "Leaf102-Int"
          paths = [
            {
              interface_type = "sub-interface"
              pod_id         = "1"
              node_id        = "102"
              interface_id   = "eth1/15"
              path_type      = "port"
              encap          = "vlan-10"
              ip_address     = "221.221.221.2/30"
            }
          ]
        }
      ]
    }
  ]

  external_epgs = [
    {
      name              = "WAN-Ext"
      provided_contract = aci_contract.contract1.id
      subnets = [
        {
          ip    = "0.0.0.0/0"
          scope = ["shared-rtctrl", "import-security", "shared-security"]
        }
      ]
    }
  ]
}
