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

module "l3out" {
  source               = "../../../l3out"
  tenant_dn            = aci_tenant.tenant.id
  name                 = "External_network"
  alias                = "l3out"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = aci_vrf.vrf.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  ospf = {
    area_cost = "1"
    area_ctrl = ["redistribute", "summary"]
    area_id   = "0"
    area_type = "regular"
  }

  logical_node_profiles = [
    {
      name = ["node1", "node2"]
      nodes = [
        {
          node_id   = "101"
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
          name = "interface1"
          ospf_interface_profile = {
            ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
            authentication_key    = "1"
          }
          paths = [
            {
              interface_type = "l3-port"
              pod_id         = "1"
              node_id        = "101"
              interface_id   = "eth1/15"
              path_type      = "port"
              ip_address     = "221.221.221.2/30"
            }
          ]
        }
      ]
    }
  ]

  external_epgs = [
    {
      name              = "all_prefixes"
      provided_contract = aci_contract.contract.id
      subnets = [
        {
          ip    = "0.0.0.0/0"
          scope = ["import-security"]
        }
      ]
    }
  ]
}
