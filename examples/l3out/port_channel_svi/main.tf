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
  name                 = "l3out"
  alias                = "l3out_simplified"
  description          = "Created by l3out module"
  import_route_control = true
  vrf_dn               = aci_vrf.vrf.id
  l3_domain_dn         = aci_l3_domain_profile.profile.id

  nodes = [
    {
      node_id          = "101"
      pod_id           = "1"
      router_id        = "102.102.102.102"
      loopback_address = "172.16.31.101"
      interfaces = [
        {
          port = "1/13"
          ip   = "14.1.1.2/24"
          ipv6 = "2001:db8:b::2/64"
        },
        {
          port                   = "1/14"
          ip                     = "14.14.14.1/24"
          secondary_ip_addresses = ["14.15.14.1/24", "14.16.14.1/24", "14.17.14.1/24"]
          vlan                   = "3"
        },
        {
          channel                = "channel-one"
          ip                     = "10.1.1.49/24"
          ipv6                   = "2001:db8:c::2/64"
          vlan                   = "4"
          svi                    = true
        },
      ]
    }
  ]
}