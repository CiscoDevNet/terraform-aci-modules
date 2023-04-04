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
  name = "common"
}

data "aci_vrf" "default" {
  tenant_dn = data.aci_tenant.common.id
  name      = "default"
}

resource "aci_l3_domain_profile" "profile" {
  name = "l3_WAN"
}

# Shared L3Out simplified module
module "l3out_shared_simplified" {
  source               = "../../../l3out"
  tenant_dn            = data.aci_tenant.common.id
  name                 = "WAN_simplified"
  alias                = "l3out_simplified"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = data.aci_vrf.default.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  nodes = [
    {
      node_id   = "103"
      pod_id    = "1"
      router_id = "201.201.201.201"
      interfaces = [
        {
          port = "1/16"
          ip   = "222.222.222.2/30"
          vlan = "11"
        }
      ]
      static_routes = [
        {
          prefix = "0.0.0.0/0"
          next_hop_addresses = [
            {
              next_hop_ip = "222.222.222.1"
            }
          ]
        }
      ]
    }
  ]

  external_epgs = [
    {
      name              = "WAN-Ext2"
      provided_contract = aci_contract.contract1.id
      subnets = [
        {
          ip    = "0.0.0.0/0"
          scope = ["export-rtctrl"]
        }
      ]
    }
  ]
}

# Shared L3Out regular module
module "l3out_shared" {
  source               = "../../../l3out"
  tenant_dn            = data.aci_tenant.common.id
  name                 = "WAN"
  alias                = "l3out"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = data.aci_vrf.default.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

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
          scope = ["export-rtctrl"]
        }
      ]
    }
  ]
}
