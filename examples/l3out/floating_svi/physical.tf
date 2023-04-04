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

# floating svi simplified module
module "l3out_floating_svi_simplified_bgp" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_floating_svi_physical_simplified"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  bgp = true

  floating_svi = {
    domain_dn                         = aci_physical_domain.physical_domain.id
    floating_ip                       = "19.1.2.30/24"
    floating_ipv6                     = "2000:db1:a::16/64"
    floating_secondary_ip_addresses   = ["19.1.2.31/24"]
    floating_secondary_ipv6_addresses = ["2000:db1:a::17/64"]
    vlan                              = "4"
    forged_transmit                   = false
    mac_change                        = false
    promiscuous_mode                  = false
    anchor_nodes = [
      {
        pod_id                   = "1"
        node_id                  = "114"
        ip_address               = "19.1.1.23/24"
        ipv6_address             = "2000:db1:a::20/64"
        secondary_ip_addresses   = ["19.1.1.26/24"]
        secondary_ipv6_addresses = ["2000:db1:a::21/64"]
        vlan                     = "2"
        bgp_peers = [
          {
            ip_address      = "19.1.2.20/24"
            address_control = ["af-ucast"]
            admin_state     = "enabled"
          },
          {
            ipv6_address    = "2000:db1:a::50/64"
            address_control = ["af-ucast"]
            admin_state     = "enabled"
          }
        ]
      },
      {
        pod_id                   = "1"
        node_id                  = "115"
        ip_address               = "19.1.1.24/24"
        ipv6_address             = "2000:db1:a::22/64"
        secondary_ip_addresses   = ["19.1.1.25/24"]
        secondary_ipv6_addresses = ["2000:db1:a::23/64"]
        vlan                     = "3"
        bgp_peers = [
          {
            ip_address      = "19.1.2.21/24"
            address_control = ["af-ucast"]
            admin_state     = "enabled"
          },
          {
            ipv6_address    = "2000:db1:a::51/64"
            address_control = ["af-ucast"]
            admin_state     = "enabled"
          },
        ]
      }
    ]
  }

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

#floating svi regular module
module "l3out_floating_svi_bgp" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_floating_svi_physical"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  bgp = true

  logical_node_profiles = [
    {
      name = "node_profile1"
      interfaces = [
        {
          name = "interface_ipv4"
          floating_svi = [
            {
              pod_id              = "1"
              node_id             = "114"
              ip_address          = "19.1.1.23/24"
              encap               = "vlan-2"
              secondary_addresses = ["19.1.1.26/24"]
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "19.1.2.30/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["19.1.2.31/24"]
                }
              ]
              bgp_peers = [
                {
                  ip_address      = "19.1.2.20/24"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                },
              ]
            },
            {
              pod_id              = "1"
              node_id             = "115"
              ip_address          = "19.1.1.24/24"
              encap               = "vlan-3"
              secondary_addresses = ["19.1.1.25/24"]
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "19.1.2.30/24"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["19.1.2.31/24"]
                }
              ]
              bgp_peers = [
                {
                  ip_address      = "19.1.2.21/24"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                },
              ]
            }
          ]
        },
        {
          name = "interface_ipv6"
          floating_svi = [
            {
              pod_id              = "1"
              node_id             = "114"
              ip_address          = "2000:db1:a::20/64"
              encap               = "vlan-2"
              secondary_addresses = ["2000:db1:a::21/64"]
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "2000:db1:a::16/64"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["2000:db1:a::17/64"]
                }
              ]
              bgp_peers = [
                {
                  ip_address      = "2000:db1:a::50/64"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                }
              ]
            },
            {
              pod_id              = "1"
              node_id             = "115"
              ip_address          = "2000:db1:a::21/64"
              encap               = "vlan-3"
              secondary_addresses = ["2000:db1:a::23/64"]
              path_attributes = [
                {
                  domain_dn           = aci_physical_domain.physical_domain.id
                  floating_address    = "2000:db1:a::16/64"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["2000:db1:a::17/64"]
                }
              ]
              bgp_peers = [
                {
                  ip_address      = "2000:db1:a::51/64"
                  address_control = ["af-ucast"]
                  admin_state     = "enabled"
                }
              ]
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