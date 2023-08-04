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

# vpc simplified module
module "l3out_vpc_simplified" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_vpc_simplified"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = true

  vpcs = [
    {
      pod_id = 1
      nodes = [
        {
          node_id            = "121"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.32.101"
        },
        {
          node_id            = "122"
          router_id          = "1.1.2.101"
          router_id_loopback = "yes"
        },
      ]
      bgp_peers = [
        {
          loopback_as_source = false
          ip_address         = "19.1.2.20/24"
          address_control    = ["af-ucast"]
          admin_state        = "enabled"
        },
        {
          loopback_as_source = false
          ipv6_address       = "2000:db1:a::50/64"
          address_control    = ["af-ucast"]
          admin_state        = "enabled"
        },
      ]
      interfaces = [
        {
          channel = "channel_vpc1"
          vlan    = "1"
          mtu     = "9000"
          side_a = {
            ip                       = "19.1.2.18/24"
            ipv6                     = "2000:db2:a::15/64"
            secondary_ip_addresses   = ["19.1.2.17/24"]
            secondary_ipv6_addresses = ["2000:db2:a::17/64"]
          }
          side_b = {
            ip                       = "19.1.2.19/24"
            ipv6                     = "2000:db2:a::16/64"
            secondary_ip_addresses   = ["19.1.2.21/24"]
            secondary_ipv6_addresses = ["2000:db2:a::18/64"]
          }
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

# vpc regular module
module "l3out_vpc" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_vpc"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  bgp = true

  logical_node_profiles = [
    {
      name = "node_profile1"
      nodes = [
        {
          node_id            = "121"
          pod_id             = "1"
          router_id          = "1.1.1.101"
          router_id_loopback = "no"
          loopback_address   = "172.16.32.101"
        },
        {
          node_id            = "122"
          pod_id             = "1"
          router_id          = "1.1.2.101"
          router_id_loopback = "yes"
        },
      ]

      interfaces = [
        {
          name = "interface_ipv4"
          paths = [
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "121"
              node2_id       = "122"
              interface_id   = "channel_vpc1"
              path_type      = "vpc"
              bgp_peers = [
                {
                  ip_address      = "19.1.2.20/24"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                }
              ]
              side_a = {
                ip_address = "19.1.2.18/24"
                secondary_addresses = [
                  {
                    ip_address = "19.1.2.17/24"
                  }
                ]
              }
              side_b = {
                ip_address = "19.1.2.19/24"
                secondary_addresses = [
                  {
                    ip_address = "19.1.2.21/24"
                  }
                ]
              }
            }
          ]
        },
        {
          name = "interface_ipv6"
          paths = [
            {
              interface_type = "ext-svi"
              pod_id         = "1"
              node_id        = "121"
              node2_id       = "122"
              interface_id   = "channel_vpc1"
              path_type      = "vpc"
              bgp_peers = [
                {
                  ip_address      = "2000:db1:a::50/64"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                }
              ]
              side_a = {
                ip_address = "2000:db2:a::15/64"
                secondary_addresses = [
                  {
                    ip_address = "2000:db2:a::17/64"
                  }
                ]
              }
              side_b = {
                ip_address = "2000:db2:a::16/64"
                secondary_addresses = [
                  {
                    ip_address = "2000:db2:a::18/64"
                  }
                ]
              }
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
