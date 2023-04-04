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

# OSPF simplified module
module "l3out_ospf_simplified" {
  source               = "../../../l3out"
  tenant_dn            = aci_tenant.tenant.id
  name                 = "OSPF_l3out_simplified"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = aci_vrf.vrf.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  ospf = {
    area_id   = "0"
    area_type = "regular"
  }

  nodes = [
    {
      node_id   = "101"
      pod_id    = "1"
      router_id = "101.101.101.101"
      ospf_interface_profile = {
        ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
      }
      interfaces = [
        {
          port = "1/15"
          ip   = "221.221.221.2/30"
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

# OSPF regular module
module "l3out_ospf" {
  source               = "../../../l3out"
  tenant_dn            = aci_tenant.tenant.id
  name                 = "OSPF_L3Out"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = aci_vrf.vrf2.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  ospf = {
    area_id   = "0"
    area_type = "regular"
  }

  logical_node_profiles = [
    {
      name = "node1"
      nodes = [
        {
          node_id   = "101"
          pod_id    = "1"
          router_id = "101.101.101.101"
        }
      ]

      interfaces = [
        {
          name = "interface1"
          ospf_interface_profile = {
            ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
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
