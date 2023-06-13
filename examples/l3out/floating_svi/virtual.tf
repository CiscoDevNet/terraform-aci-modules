# floating svi simplified module
module "l3out_floating_svi_simplified_ospf" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_floating_svi_virtual_simplified"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf.id

  ospf = {
    area_id   = "0"
    area_type = "regular"
  }

  floating_svi = {
    domain_dn                         = aci_vmm_domain.virtual_domain.id
    floating_ipv6                     = "2000:db1:a::16/64"
    floating_secondary_ipv6_addresses = ["2000:db1:a::17/64"]
    forged_transmit                   = false
    mac_change                        = false
    promiscuous_mode                  = false
    ospf_interface_profile = {
      ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
      authentication_key_id = "1"
    }
    anchor_nodes = [
      {
        pod_id                   = "1"
        node_id                  = "114"
        ipv6_address             = "2000:db1:a::20/64"
        secondary_ipv6_addresses = ["2000:db1:a::21/64"]
        vlan                     = "2"
      },
      {
        pod_id                   = "1"
        node_id                  = "115"
        ipv6_address             = "2000:db1:a::22/64"
        secondary_ipv6_addresses = ["2000:db1:a::23/64"]
        vlan                     = "3"
      },
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
module "l3out_floating_svi_ospf" {
  source      = "../../../l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_l3out_floating_svi_virtual"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  ospf = {
    area_id   = "0"
    area_type = "regular"
  }

  logical_node_profiles = [
    {
      name = "node_profile1"
      interfaces = [
        {
          name = "interface_ipv6"
          ospf_interface_profile = {
            ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
          }
          floating_svi = [
            {
              pod_id              = "1"
              node_id             = "114"
              ip_address          = "2000:db1:a::20/64"
              encap               = "vlan-2"
              secondary_addresses = ["2000:db1:a::21/64"]
              path_attributes = [
                {
                  domain_dn           = aci_vmm_domain.virtual_domain2.id
                  floating_address    = "2000:db1:a::16/64"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["2000:db1:a::17/64"]
                }
              ]
            },
            {
              pod_id     = "1"
              node_id    = "115"
              ip_address = "2000:db1:a::21/64"
              encap      = "vlan-3"
              path_attributes = [
                {
                  domain_dn           = aci_vmm_domain.virtual_domain2.id
                  floating_address    = "2000:db1:a::16/64"
                  forged_transmit     = false
                  mac_change          = false
                  promiscuous_mode    = false
                  secondary_addresses = ["2000:db1:a::17/64"]
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