<!-- BEGIN_TF_DOCS -->
# ACI L3Out Terraform module

Terraform module which creates L3Out resources on ACI.

## Types

There are a few ways of using this module:

- Simplified Structure: The L3Out logical interface profiles can be created using a simplified approach with minimal syntax.

- Complete Structure: The L3Out resources can be created using a comprehensive approach which gives the user the complete set of options available in the provider today.

The main difference between the two structures is that the various interface types can be defined discretely without the complete logical node and logical interface configuration in the simplified structure.

## Common attributes between the simplified and the complete structure

Prior to defining the logical node profiles and logical interface profiles in the module, both the structures share a few attributes as shown below:

```hcl
module "l3out_bgp" {
  source      = "terraform-aci-modules/l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "l3out_bgp"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf1.id

  bgp = true
}

module "l3out_ospf" {
  source      = "terraform-aci-modules/l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "l3out_ospf"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  ospf = {
    area_cost = "1"
    area_ctrl = ["redistribute"]
    area_id   = "2"
    area_type = "regular"
  }

  ospf_interface_profile = {
    ospf_interface_policy = aci_ospf_interface_policy.ospf_interface_policy.id
    authentication_key_id = "1"
  }
}
```

## Features of the Simplified structure
* [`Routed Interface, Routed Sub-Interface, SVI`](https://github.com/shrsr/terraform-aci-modules/tree/l3out/examples/l3out/port_channel_svi)

* [`Floating SVI`](https://github.com/shrsr/terraform-aci-modules/tree/l3out/examples/l3out/floating_svi)

* [`VPC`](https://github.com/shrsr/terraform-aci-modules/tree/l3out/examples/l3out/vpc)

* BGP Peers for the simplified structure can be defined in three levels. It has a special attribute called `loopback_as_source` whose default value is `true`.
  - When a BGP peer is defined at the global level, it gets pushed to all the nodes in the module when `loopback_as_source` is `true`. If `loopback_as_source` is `false` it gets pushed to all the interfaces.
  - When a BGP peer is defined at the node level, it gets pushed to the respective node if `loopback_as_source` is `true` otherwise it gets pushed to all the interfaces associated with the said node.
  - BGP peers defined at the interface level get pushed to their respective interfaces.
  - IPv4 and IPv6 BGP peers associate themselves with their respective address families contained in the node and interface levels.

### BGP Peers defined with loopback_as_source

```hcl
module "l3out_svi_bgp" {
  source      = "terraform-aci-modules/l3out"
  tenant_dn   = aci_tenant.tenant.id
  name        = "module_simplified_svi_bgp"
  description = "Created by l3out module"
  vrf_dn      = aci_vrf.vrf2.id

  bgp = true

  bgp_peers = [
    {
      loopback_as_source  = false
      ip_address          = "10.1.1.13"
      address_control     = ["af-mcast", "af-ucast"]
      allowed_self_as_cnt = "1"
      bgp_controls = {
        send_com = true
      }
      peer_controls      = ["bfd"]
      private_as_control = ["remove-all", "remove-exclusive"]
      admin_state        = "enabled"
      route_control_profiles = [
        {
          direction = "export"
          target_dn = aci_route_control_profile.profile2.id
        }
      ]
    }
  ]

  nodes = [
    {
      node_id          = "101"
      pod_id           = "1"
      router_id        = "110.110.110.110"
      loopback_address = "172.16.31.109"
      bgp_peers = [
        {
          loopback_as_source  = false
          ip_address          = "10.1.1.55"
          address_control     = ["af-mcast", "af-ucast"]
          allowed_self_as_cnt = "1"
          bgp_controls = {
            send_com = true
          }
          peer_controls      = ["bfd"]
          private_as_control = ["remove-all", "remove-exclusive"]
          admin_state        = "enabled"
          route_control_profiles = [
            {
              direction = "export"
              target_dn = aci_route_control_profile.profile2.id
            }
          ]
        },
      ]
      interfaces = [
        {
          port = "1/15"
          ip   = "10.1.1.18/24"
          ipv6 = "2001:db8:e::3/64"
          bgp_peers = [
            {
              ip_address          = "10.1.1.27"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              bgp_controls = {
                as_override = true
              }
              peer_controls      = ["bfd"]
              private_as_control = ["remove-all", "remove-exclusive"]
              admin_state        = "enabled"
            },
            {
              ipv6_address        = "2001:db7:e::3/64"
              address_control     = ["af-mcast", "af-ucast"]
              allowed_self_as_cnt = "1"
              peer_controls       = ["bfd"]
              private_as_control  = ["remove-all", "remove-exclusive"]
              admin_state         = "disabled"
            },
          ]
        },
      ]
    }
  ]
}
```

## Features of the complete structure

The complete structure gives the user all the options available in the Terraform ACI provider. This can be used when the user requires additional attributes to be configured which are not supported in the simplified structure.
See [`Example`](https://github.com/shrsr/terraform-aci-modules/tree/l3out/examples/l3out/comprehensive/complete_syntax)

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aci"></a> [aci](#provider\_aci) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aci_bgp_peer_connectivity_profile.bgp_peer_anchor_node_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.bgp_peer_anchor_node_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.floating_svi_bgp_peer](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.global_vpc_interfaces_bgp_peer_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.global_vpc_interfaces_bgp_peer_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.global_vpc_node_bgp_peers](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interface_bgp_peer](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interface_bgp_peer_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interface_bgp_peer_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interfaces_bgp_peer_from_global_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interfaces_bgp_peer_from_global_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interfaces_bgp_peer_from_node_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.interfaces_bgp_peer_from_node_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.node_bgp_peer](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.node_bgp_peers](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.node_bgp_peers_global](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.vpc_interface_bgp_peer_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.vpc_interface_bgp_peer_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.vpc_interfaces_bgp_peer_from_global_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.vpc_interfaces_bgp_peer_from_global_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_bgp_peer_connectivity_profile.vpc_node_bgp_peers](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/bgp_peer_connectivity_profile) | resource |
| [aci_external_network_instance_profile.l3out_external_epgs](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/external_network_instance_profile) | resource |
| [aci_l3_ext_subnet.external_epg_subnets](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3_ext_subnet) | resource |
| [aci_l3_outside.l3out](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3_outside) | resource |
| [aci_l3out_bfd_interface_profile.bfd_interface](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_bfd_interface_profile) | resource |
| [aci_l3out_bgp_external_policy.external_bgp](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_bgp_external_policy) | resource |
| [aci_l3out_bgp_protocol_profile.bgp_protocol](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_bgp_protocol_profile) | resource |
| [aci_l3out_floating_svi.floating_svi](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_floating_svi) | resource |
| [aci_l3out_floating_svi.floating_svi_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_floating_svi) | resource |
| [aci_l3out_floating_svi.floating_svi_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_floating_svi) | resource |
| [aci_l3out_hsrp_interface_group.hsrp_group](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_hsrp_interface_group) | resource |
| [aci_l3out_hsrp_interface_profile.hsrp_interface](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_hsrp_interface_profile) | resource |
| [aci_l3out_hsrp_secondary_vip.secondary_virtual_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_hsrp_secondary_vip) | resource |
| [aci_l3out_loopback_interface_profile.dynamic_loopback_interfaces](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_loopback_interface_profile) | resource |
| [aci_l3out_loopback_interface_profile.loopback_interface](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_loopback_interface_profile) | resource |
| [aci_l3out_loopback_interface_profile.vpc_dynamic_loopback_interfaces](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_loopback_interface_profile) | resource |
| [aci_l3out_ospf_external_policy.ospf](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_external_policy) | resource |
| [aci_l3out_ospf_interface_profile.floating_svi_ospf_interface_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.floating_svi_ospf_interface_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.gloabl_dynamic_ospf_interface_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.gloabl_node_dynamic_ospf_interface_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_dynamic_ospf_interface_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_node_dynamic_ospf_interface_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_node_vpc_ospf_interface_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_node_vpc_ospf_interface_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_vpc_ospf_interface_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.global_vpc_ospf_interface_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_ospf_interface_profile.ospf_interface](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_ospf_interface_profile) | resource |
| [aci_l3out_path_attachment.dynamic_l3out_path_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment.dynamic_l3out_path_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment.l3out_path](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment.vpc_l3out_path_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment.vpc_l3out_path_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment) | resource |
| [aci_l3out_path_attachment_secondary_ip.floating_svi_anchor_node_secondary_ip_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.floating_svi_anchor_node_secondary_ipv6_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.floating_svi_secondary_ip_addr](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.floating_svi_secondary_ip_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.floating_svi_secondary_ipv6_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ip_addr](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ip_addr_A](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ip_addr_B](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ip_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ip_addresses_floating_svi](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.secondary_ipv6_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.vpc_secondary_ip_addr_A](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.vpc_secondary_ip_addr_B](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.vpc_secondary_ipv6_addr_A](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_path_attachment_secondary_ip.vpc_secondary_ipv6_addr_B](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_path_attachment_secondary_ip) | resource |
| [aci_l3out_static_route.dynamic_static_routes](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route) | resource |
| [aci_l3out_static_route.static_route](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route) | resource |
| [aci_l3out_static_route.vpc_dynamic_static_routes](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route) | resource |
| [aci_l3out_static_route_next_hop.dynamic_next_hop_addresses](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route_next_hop) | resource |
| [aci_l3out_static_route_next_hop.next_hop_address](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route_next_hop) | resource |
| [aci_l3out_static_route_next_hop.vpc_dynamic_next_hop_addresses](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_static_route_next_hop) | resource |
| [aci_l3out_vpc_member.side_A](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l3out_vpc_member.side_B](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l3out_vpc_member.vpc_side_A_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l3out_vpc_member.vpc_side_A_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l3out_vpc_member.vpc_side_B_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_l3out_vpc_member.vpc_side_B_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/l3out_vpc_member) | resource |
| [aci_logical_interface_profile.dynamic_logical_interface_profile_floating_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.dynamic_logical_interface_profile_floating_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.dynamic_logical_interface_profile_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.dynamic_logical_interface_profile_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.logical_interface_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.vpc_dynamic_logical_interface_profile_ip](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_interface_profile.vpc_dynamic_logical_interface_profile_ipv6](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_interface_profile) | resource |
| [aci_logical_node_profile.dynamic_logical_node_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_profile) | resource |
| [aci_logical_node_profile.dynamic_logical_node_profile_floating](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_profile) | resource |
| [aci_logical_node_profile.logical_node_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_profile) | resource |
| [aci_logical_node_profile.vpc_dynamic_logical_node_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_profile) | resource |
| [aci_logical_node_to_fabric_node.dynamic_fabric_nodes](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_to_fabric_node) | resource |
| [aci_logical_node_to_fabric_node.logical_node_fabric](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_to_fabric_node) | resource |
| [aci_logical_node_to_fabric_node.vpc_dynamic_fabric_nodes](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/logical_node_to_fabric_node) | resource |
| [aci_rest_managed.l3out_bfd_multihop_interface_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_bfd_multihop_protocol_profile](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_consumer_label](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_default_route_leak_policy](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_fallback_route_group](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_rest_managed.l3out_multicast](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/rest_managed) | resource |
| [aci_route_control_context.route_control_context](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/route_control_context) | resource |
| [aci_route_control_profile.l3out_route_control](https://registry.terraform.io/providers/ciscoDevNet/aci/latest/docs/resources/route_control_profile) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias"></a> [alias](#input\_alias) | Name alias of the L3Out object | `string` | `""` | no |
| <a name="input_annotation"></a> [annotation](#input\_annotation) | Annotation of the L3Out object | `string` | `"orchestrator:terraform"` | no |
| <a name="input_bgp"></a> [bgp](#input\_bgp) | L3Out BGP protocol | `bool` | `false` | no |
| <a name="input_bgp_peers"></a> [bgp\_peers](#input\_bgp\_peers) | BGP Peers definition at the global level. It gets pushed to all the nodes in the module when `loopback_as_source` is `true`. If `loopback_as_source` is `false` it gets pushed to all the interfaces. | <pre>list(object(<br>    {<br>      loopback_as_source  = optional(bool)<br>      ip_address          = optional(string)<br>      ipv6_address        = optional(string)<br>      address_control     = optional(list(string))<br>      allowed_self_as_cnt = optional(string)<br>      annotation          = optional(string)<br>      bgp_controls = optional(object(<br>        {<br>          allow_self_as     = optional(bool)<br>          as_override       = optional(bool)<br>          dis_peer_as_check = optional(bool)<br>          nh_self           = optional(bool)<br>          send_com          = optional(bool)<br>          send_ext_com      = optional(bool)<br>        }<br>      ))<br>      alias                  = optional(string)<br>      password               = optional(string)<br>      peer_controls          = optional(list(string))<br>      private_as_control     = optional(list(string))<br>      ebgp_multihop_ttl      = optional(string)<br>      weight                 = optional(string)<br>      as_number              = optional(string)<br>      local_asn              = optional(string)<br>      local_as_number_config = optional(string)<br>      admin_state            = optional(string)<br>      route_control_profiles = optional(list(object({<br>        direction = string<br>        target_dn = string<br>        }<br>      )))<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "loopback_as_source": true<br>  }<br>]</pre> | no |
| <a name="input_consumer_label"></a> [consumer\_label](#input\_consumer\_label) | L3Out Consumer Label | `string` | `""` | no |
| <a name="input_default_route_leak_policy"></a> [default\_route\_leak\_policy](#input\_default\_route\_leak\_policy) | Route Profile for Interleak Policy | <pre>object({<br>    criteria = optional(string)<br>    always   = optional(string)<br>    scope    = optional(list(string))<br>    }<br>  )</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | L3Out description | `string` | `""` | no |
| <a name="input_external_epgs"></a> [external\_epgs](#input\_external\_epgs) | L3Out External EPGs Block | <pre>list(object(<br>    {<br>      annotation                   = optional(string)<br>      description                  = optional(string)<br>      exception_tag                = optional(string)<br>      label_match_criteria         = optional(string)<br>      alias                        = optional(string)<br>      name                         = string<br>      preferred_group_member       = optional(bool)<br>      qos_class                    = optional(string)<br>      target_dscp                  = optional(string)<br>      provided_contracts           = optional(list(string))<br>      consumed_contract_interfaces = optional(list(string))<br>      consumed_contracts           = optional(list(string))<br>      taboo_contracts              = optional(list(string))<br>      inherited_contracts          = optional(list(string))<br>      contract_masters = optional(list(object(<br>        {<br>          external_epg = string<br>          l3out        = string<br>        }<br>      )))<br>      route_control_profiles = optional(list(object(<br>        {<br>          direction    = string<br>          route_map_dn = string<br>        }<br>      )))<br>      subnets = optional(list(object(<br>        {<br>          ip        = string<br>          aggregate = optional(string)<br>          alias     = optional(string)<br>          scope     = list(string)<br>          route_control_profiles = optional(list(object(<br>            {<br>              direction    = string<br>              route_map_dn = string<br>            }<br>          )))<br>        }<br>      )))<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_fallback_route_group_dns"></a> [fallback\_route\_group\_dns](#input\_fallback\_route\_group\_dns) | n/a | `list(string)` | `[]` | no |
| <a name="input_floating_svi"></a> [floating\_svi](#input\_floating\_svi) | Simplified Block for defining L3out Floating SVI | <pre>object(<br>    {<br>      domain_dn                         = optional(string)<br>      floating_ip                       = optional(string)<br>      floating_ipv6                     = optional(string)<br>      forged_transmit                   = optional(bool)<br>      mac_change                        = optional(bool)<br>      promiscuous_mode                  = optional(bool)<br>      floating_secondary_ip_addresses   = optional(list(string))<br>      floating_secondary_ipv6_addresses = optional(list(string))<br>      vlan                              = optional(string)<br>      ospf_interface_profile = optional(object(<br>        {<br>          authentication_key    = optional(string)<br>          authentication_key_id = optional(string)<br>          authentication_type   = optional(string)<br>          ospf_interface_policy = optional(string)<br>          description           = optional(string)<br>          annotation            = optional(string)<br>        }<br>      ))<br>      anchor_nodes = optional(list(object(<br>        {<br>          pod_id                   = string<br>          node_id                  = string<br>          ip_address               = optional(string)<br>          ipv6_address             = optional(string)<br>          secondary_ip_addresses   = optional(list(string))<br>          secondary_ipv6_addresses = optional(list(string))<br>          description              = optional(string)<br>          mtu                      = optional(string)<br>          vlan                     = optional(string)<br>          encap_scope              = optional(string)<br>          mode                     = optional(string)<br>          annotation               = optional(string)<br>          autostate                = optional(string)<br>          ipv6_dad                 = optional(string)<br>          link_local_address       = optional(string)<br>          mac                      = optional(string)<br>          target_dscp              = optional(string)<br>          bgp_peers = optional(list(object(<br>            {<br>              ip_address          = optional(string)<br>              ipv6_address        = optional(string)<br>              address_control     = optional(list(string))<br>              allowed_self_as_cnt = optional(string)<br>              annotation          = optional(string)<br>              bgp_controls = optional(object(<br>                {<br>                  allow_self_as     = optional(bool)<br>                  as_override       = optional(bool)<br>                  dis_peer_as_check = optional(bool)<br>                  nh_self           = optional(bool)<br>                  send_com          = optional(bool)<br>                  send_ext_com      = optional(bool)<br>                }<br>              ))<br>              alias                  = optional(string)<br>              password               = optional(string)<br>              peer_controls          = optional(list(string))<br>              private_as_control     = optional(list(string))<br>              ebgp_multihop_ttl      = optional(string)<br>              weight                 = optional(string)<br>              as_number              = optional(string)<br>              local_asn              = optional(string)<br>              local_as_number_config = optional(string)<br>              admin_state            = optional(string)<br>              route_control_profiles = optional(list(object({<br>                direction = string<br>                target_dn = string<br>                }<br>              )))<br>            }<br>          )))<br>        }<br>      )))<br>  })</pre> | <pre>{<br>  "anchor_nodes": []<br>}</pre> | no |
| <a name="input_import_route_control"></a> [import\_route\_control](#input\_import\_route\_control) | Import route control profile | `bool` | `false` | no |
| <a name="input_l3_domain_dn"></a> [l3\_domain\_dn](#input\_l3\_domain\_dn) | Distinguished name of the L3 Domain | `string` | `""` | no |
| <a name="input_logical_node_profiles"></a> [logical\_node\_profiles](#input\_logical\_node\_profiles) | Logical Node Profiles Block | <pre>list(object(<br>    {<br>      annotation  = optional(string)<br>      description = optional(string)<br>      alias       = optional(string)<br>      name        = string<br>      tag         = optional(string)<br>      target_dscp = optional(string)<br>      bgp_peers_nodes = optional(list(object({<br>        ip_address          = string<br>        address_control     = optional(list(string))<br>        allowed_self_as_cnt = optional(string)<br>        annotation          = optional(string)<br>        bgp_controls = optional(object(<br>          {<br>            allow_self_as     = optional(bool)<br>            as_override       = optional(bool)<br>            dis_peer_as_check = optional(bool)<br>            nh_self           = optional(bool)<br>            send_com          = optional(bool)<br>            send_ext_com      = optional(bool)<br>        }))<br>        alias                  = optional(string)<br>        password               = optional(string)<br>        peer_controls          = optional(list(string))<br>        private_as_control     = optional(list(string))<br>        ebgp_multihop_ttl      = optional(string)<br>        weight                 = optional(string)<br>        as_number              = optional(string)<br>        local_asn              = optional(string)<br>        local_as_number_config = optional(string)<br>        admin_state            = optional(string)<br>        route_control_profiles = optional(list(object({<br>          direction = string<br>          target_dn = string<br>          }<br>        )))<br>        }<br>      )))<br>      bgp_protocol_profile = optional(object(<br>        {<br>          bgp_timers     = optional(string)<br>          as_path_policy = optional(string)<br>        }<br>      ))<br>      bfd_multihop_protocol_profile = optional(object(<br>        {<br>          authentication_type           = optional(string)<br>          authentication_key_id         = optional(string)<br>          authentication_key            = optional(string)<br>          bfd_multihop_node_policy_name = string<br>        }<br>      ))<br>      nodes = optional(list(object(<br>        {<br>          node_id            = string<br>          pod_id             = string<br>          router_id          = optional(string)<br>          router_id_loopback = optional(string)<br>          loopback_address   = optional(string)<br>          static_routes = optional(list(object({<br>            ip                  = string<br>            alias               = optional(string)<br>            description         = optional(string)<br>            fallback_preference = optional(string)<br>            route_control       = optional(bool)<br>            track_policy        = optional(string)<br>            next_hop_addresses = optional(list(object({<br>              next_hop_ip          = string<br>              annotation           = optional(string)<br>              alias                = optional(string)<br>              preference           = optional(string)<br>              nexthop_profile_type = optional(string)<br>              description          = optional(string)<br>              track_member         = optional(string)<br>              track_policy         = optional(string)<br>              }<br>            )))<br>            }<br>          )))<br>        }<br>      )))<br>      interfaces = optional(list(object(<br>        {<br>          name = string<br>          ospf_interface_profile = optional(object(<br>            {<br>              authentication_key    = optional(string)<br>              authentication_key_id = optional(string)<br>              authentication_type   = optional(string)<br>              ospf_interface_policy = optional(string)<br>              description           = optional(string)<br>              annotation            = optional(string)<br>            }<br>          ))<br>          bfd_interface_profile = optional(object(<br>            {<br>              authentication_key     = optional(string)<br>              authentication_key_id  = optional(string)<br>              interface_profile_type = optional(string)<br>              description            = optional(string)<br>              annotation             = optional(string)<br>              bfd_interface_policy   = optional(string)<br>            }<br>          ))<br>          bfd_multihop_interface_profile = optional(object(<br>            {<br>              authentication_key                 = optional(string)<br>              authentication_key_id              = optional(string)<br>              authentication_type                = optional(string)<br>              bfd_multihop_interface_policy_name = string<br>            }<br>          ))<br>          hsrp = optional(object(<br>            {<br>              annotation = optional(string)<br>              alias      = optional(string)<br>              version    = optional(string)<br>              hsrp_groups = optional(list(object({<br>                name                  = string<br>                annotation            = optional(string)<br>                description           = optional(string)<br>                address_family        = optional(string)<br>                group_id              = optional(string)<br>                ip                    = optional(string)<br>                ip_obtain_mode        = optional(string)<br>                mac                   = optional(string)<br>                alias                 = optional(string)<br>                secondary_virtual_ips = optional(list(string))<br>                }<br>              )))<br>            }<br>          ))<br>          netflow_monitor_policies = optional(list(object(<br>            {<br>              filter_type                 = string<br>              netflow_monitor_policy_name = string<br>            }<br>          )))<br>          egress_data_policy_dn  = optional(string)<br>          ingress_data_policy_dn = optional(string)<br>          custom_qos_policy_dn   = optional(string)<br>          nd_policy_dn           = optional(string)<br>          paths = optional(list(object(<br>            {<br>              interface_type     = string<br>              path_type          = string<br>              pod_id             = string<br>              node_id            = string<br>              node2_id           = optional(string)<br>              interface_id       = string<br>              ip_address         = optional(string)<br>              mtu                = optional(string)<br>              encap              = optional(string)<br>              encap_scope        = optional(string)<br>              mode               = optional(string)<br>              annotation         = optional(string)<br>              autostate          = optional(string)<br>              ipv6_dad           = optional(string)<br>              link_local_address = optional(string)<br>              mac                = optional(string)<br>              target_dscp        = optional(string)<br>              bgp_peers = optional(list(object({<br>                ip_address          = string<br>                address_control     = optional(list(string))<br>                allowed_self_as_cnt = optional(string)<br>                annotation          = optional(string)<br>                bgp_controls = optional(object(<br>                  {<br>                    allow_self_as     = optional(bool)<br>                    as_override       = optional(bool)<br>                    dis_peer_as_check = optional(bool)<br>                    nh_self           = optional(bool)<br>                    send_com          = optional(bool)<br>                    send_ext_com      = optional(bool)<br>                  }<br>                ))<br>                alias                  = optional(string)<br>                password               = optional(string)<br>                peer_controls          = optional(list(string))<br>                private_as_control     = optional(list(string))<br>                ebgp_multihop_ttl      = optional(string)<br>                weight                 = optional(string)<br>                as_number              = optional(string)<br>                local_asn              = optional(string)<br>                local_as_number_config = optional(string)<br>                admin_state            = optional(string)<br>                route_control_profiles = optional(list(object({<br>                  direction = string<br>                  target_dn = string<br>                  }<br>                )))<br>                }<br>              )))<br>              secondary_addresses = optional(list(object(<br>                {<br>                  ip_address = string<br>                  ipv6_dad   = optional(string)<br>                }<br>              )))<br>              side_a = optional(object({<br>                ip_address         = string<br>                link_local_address = optional(string)<br>                secondary_addresses = optional(list(object(<br>                  {<br>                    ip_address = string<br>                    ipv6_dad   = optional(string)<br>                  }<br>                )))<br>                }<br>              ))<br>              side_b = optional(object(<br>                {<br>                  ip_address         = string<br>                  link_local_address = optional(string)<br>                  secondary_addresses = optional(list(object(<br>                    {<br>                      ip_address = string<br>                      ipv6_dad   = optional(string)<br>                    }<br>                  )))<br>                }<br>              ))<br>            }<br>          )))<br>          floating_svi = optional(list(object(<br>            {<br>              pod_id              = string<br>              node_id             = string<br>              ip_address          = string<br>              secondary_addresses = optional(list(string))<br>              description         = optional(string)<br>              mtu                 = optional(string)<br>              encap               = optional(string)<br>              encap_scope         = optional(string)<br>              mode                = optional(string)<br>              annotation          = optional(string)<br>              autostate           = optional(string)<br>              ipv6_dad            = optional(string)<br>              link_local_address  = optional(string)<br>              mac                 = optional(string)<br>              target_dscp         = optional(string)<br>              path_attributes = optional(list(object(<br>                {<br>                  domain_dn           = string<br>                  floating_address    = string<br>                  forged_transmit     = optional(bool)<br>                  mac_change          = optional(bool)<br>                  promiscuous_mode    = optional(bool)<br>                  secondary_addresses = optional(list(string))<br>                }<br>              )))<br>              bgp_peers = optional(list(object(<br>                {<br>                  ip_address          = string<br>                  address_control     = optional(list(string))<br>                  allowed_self_as_cnt = optional(string)<br>                  annotation          = optional(string)<br>                  bgp_controls = optional(object(<br>                    {<br>                      allow_self_as     = optional(bool)<br>                      as_override       = optional(bool)<br>                      dis_peer_as_check = optional(bool)<br>                      nh_self           = optional(bool)<br>                      send_com          = optional(bool)<br>                      send_ext_com      = optional(bool)<br>                    }<br>                  ))<br>                  alias                  = optional(string)<br>                  password               = optional(string)<br>                  peer_controls          = optional(list(string))<br>                  private_as_control     = optional(list(string))<br>                  ebgp_multihop_ttl      = optional(string)<br>                  weight                 = optional(string)<br>                  as_number              = optional(string)<br>                  local_asn              = optional(string)<br>                  local_as_number_config = optional(string)<br>                  admin_state            = optional(string)<br>                  route_control_profiles = optional(list(object({<br>                    direction = string<br>                    target_dn = string<br>                    }<br>                  )))<br>                }<br>              )))<br>            }<br>          )))<br>        }<br>      )))<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_multicast"></a> [multicast](#input\_multicast) | n/a | <pre>object(<br>    {<br>      annotation       = optional(string)<br>      address_families = optional(list(string))<br>    }<br>  )</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | L3Out Name | `string` | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Simplified Block for defining nodes and associate Port, Channel or SVI interfaces | <pre>list(object(<br>    {<br>      node_id            = optional(string)<br>      pod_id             = optional(string)<br>      router_id          = optional(string)<br>      router_id_loopback = optional(string)<br>      loopback_address   = optional(string)<br>      static_routes = optional(list(object(<br>        {<br>          prefix              = string<br>          fallback_preference = optional(string)<br>          route_control       = optional(bool)<br>          track_policy        = optional(string)<br>          next_hop_addresses = optional(list(object(<br>            {<br>              next_hop_ip           = string<br>              preference            = optional(string)<br>              next_hop_profile_type = optional(string)<br>              track_member          = optional(string)<br>              track_policy          = optional(string)<br><br>            }<br>          )))<br>        }<br>      )))<br>      ospf_interface_profile = optional(object(<br>        {<br>          authentication_key    = optional(string)<br>          authentication_key_id = optional(string)<br>          authentication_type   = optional(string)<br>          ospf_interface_policy = optional(string)<br>          description           = optional(string)<br>          annotation            = optional(string)<br>        }<br>      ))<br>      bgp_peers = optional(list(object(<br>        {<br>          loopback_as_source  = optional(bool)<br>          ip_address          = optional(string)<br>          ipv6_address        = optional(string)<br>          address_control     = optional(list(string))<br>          allowed_self_as_cnt = optional(string)<br>          annotation          = optional(string)<br>          bgp_controls = optional(object(<br>            {<br>              allow_self_as     = optional(bool)<br>              as_override       = optional(bool)<br>              dis_peer_as_check = optional(bool)<br>              nh_self           = optional(bool)<br>              send_com          = optional(bool)<br>              send_ext_com      = optional(bool)<br>            }<br>          ))<br>          alias                  = optional(string)<br>          password               = optional(string)<br>          peer_controls          = optional(list(string))<br>          private_as_control     = optional(list(string))<br>          ebgp_multihop_ttl      = optional(string)<br>          weight                 = optional(string)<br>          as_number              = optional(string)<br>          local_asn              = optional(string)<br>          local_as_number_config = optional(string)<br>          admin_state            = optional(string)<br>          route_control_profiles = optional(list(object({<br>            direction = string<br>            target_dn = string<br>            }<br>          )))<br>        }<br>      )))<br>      interfaces = optional(list(object(<br>        {<br>          svi                      = optional(bool)<br>          anchor_node              = optional(string)<br>          port                     = optional(string)<br>          channel                  = optional(string)<br>          ip                       = optional(string)<br>          ipv6                     = optional(string)<br>          link_local_address       = optional(string)<br>          secondary_ip_addresses   = optional(list(string))<br>          secondary_ipv6_addresses = optional(list(string))<br>          vlan                     = optional(string)<br>          bgp_peers = optional(list(object(<br>            {<br>              ip_address          = optional(string)<br>              ipv6_address        = optional(string)<br>              address_control     = optional(list(string))<br>              allowed_self_as_cnt = optional(string)<br>              annotation          = optional(string)<br>              bgp_controls = optional(object(<br>                {<br>                  allow_self_as     = optional(bool)<br>                  as_override       = optional(bool)<br>                  dis_peer_as_check = optional(bool)<br>                  nh_self           = optional(bool)<br>                  send_com          = optional(bool)<br>                  send_ext_com      = optional(bool)<br>                }<br>              ))<br>              alias                  = optional(string)<br>              password               = optional(string)<br>              peer_controls          = optional(list(string))<br>              private_as_control     = optional(list(string))<br>              ebgp_multihop_ttl      = optional(string)<br>              weight                 = optional(string)<br>              as_number              = optional(string)<br>              local_asn              = optional(string)<br>              local_as_number_config = optional(string)<br>              admin_state            = optional(string)<br>              route_control_profiles = optional(list(object({<br>                direction = string<br>                target_dn = string<br>                }<br>              )))<br>            }<br>          )))<br>        }<br>      )))<br>  }))</pre> | <pre>[<br>  {<br>    "loopback_as_source": true<br>  }<br>]</pre> | no |
| <a name="input_ospf"></a> [ospf](#input\_ospf) | OSPF External Policy | <pre>object(<br>    {<br>      area_id   = optional(string)<br>      area_type = optional(string)<br>      area_cost = optional(string)<br>      area_ctrl = optional(list(string))<br>    }<br>  )</pre> | `null` | no |
| <a name="input_ospf_interface_profile"></a> [ospf\_interface\_profile](#input\_ospf\_interface\_profile) | OSPF Interface Profile | <pre>object(<br>    {<br>      authentication_key    = optional(string)<br>      authentication_key_id = optional(string)<br>      authentication_type   = optional(string)<br>      ospf_interface_policy = optional(string)<br>      description           = optional(string)<br>      annotation            = optional(string)<br>    }<br>  )</pre> | `null` | no |
| <a name="input_route_control_for_dampening"></a> [route\_control\_for\_dampening](#input\_route\_control\_for\_dampening) | Route Control for Dampening | <pre>list(object(<br>    {<br>      address_family = optional(string) # choose between ipv4 and v6<br>      route_map_dn   = optional(string)<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_route_control_for_interleak_redistribution"></a> [route\_control\_for\_interleak\_redistribution](#input\_route\_control\_for\_interleak\_redistribution) | n/a | <pre>list(object(<br>    {<br>      source       = optional(string)<br>      route_map_dn = optional(string)<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_route_map_control_profiles"></a> [route\_map\_control\_profiles](#input\_route\_map\_control\_profiles) | Route Control Profiles | <pre>list(object(<br>    {<br>      annotation                 = optional(string)<br>      description                = optional(string)<br>      alias                      = optional(string)<br>      name                       = string<br>      route_control_profile_type = optional(string)<br>      contexts = optional(list(object(<br>        {<br>          name           = string<br>          action         = optional(string)<br>          order          = optional(string)<br>          set_rule_dn    = optional(string)<br>          match_rules_dn = optional(list(string))<br>        }<br>      )))<br>    }<br>  ))</pre> | `[]` | no |
| <a name="input_target_dscp"></a> [target\_dscp](#input\_target\_dscp) | The target differentiated services code point (DSCP) of the path attached to the L3 Outside object | `string` | `"unspecified"` | no |
| <a name="input_tenant_dn"></a> [tenant\_dn](#input\_tenant\_dn) | Distinguished name of the parent Tenant object | `string` | n/a | yes |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | Simplified Block for defining VPCs | <pre>list(object(<br>    {<br>      pod_id = optional(string)<br>      nodes = optional(list(object(<br>        {<br>          node_id            = optional(string)<br>          router_id          = optional(string)<br>          router_id_loopback = optional(string)<br>          loopback_address   = optional(string)<br>        }<br>      )))<br>      interfaces = optional(list(object(<br>        {<br>          channel = optional(string)<br>          vlan    = optional(string)<br>          side_a = object(<br>            {<br>              ip                       = optional(string)<br>              ipv6                     = optional(string)<br>              link_local_address       = optional(string)<br>              secondary_ip_addresses   = optional(list(string))<br>              secondary_ipv6_addresses = optional(list(string))<br>          })<br>          side_b = object(<br>            {<br>              ip                       = optional(string)<br>              ipv6                     = optional(string)<br>              link_local_address       = optional(string)<br>              secondary_ip_addresses   = optional(list(string))<br>              secondary_ipv6_addresses = optional(list(string))<br>          })<br>          bgp_peers = optional(list(object(<br>            {<br>              ip_address          = optional(string)<br>              ipv6_address        = optional(string)<br>              address_control     = optional(list(string))<br>              allowed_self_as_cnt = optional(string)<br>              annotation          = optional(string)<br>              bgp_controls = optional(object(<br>                {<br>                  allow_self_as     = optional(bool)<br>                  as_override       = optional(bool)<br>                  dis_peer_as_check = optional(bool)<br>                  nh_self           = optional(bool)<br>                  send_com          = optional(bool)<br>                  send_ext_com      = optional(bool)<br>                }<br>              ))<br>              alias                  = optional(string)<br>              password               = optional(string)<br>              peer_controls          = optional(list(string))<br>              private_as_control     = optional(list(string))<br>              ebgp_multihop_ttl      = optional(string)<br>              weight                 = optional(string)<br>              as_number              = optional(string)<br>              local_asn              = optional(string)<br>              local_as_number_config = optional(string)<br>              admin_state            = optional(string)<br>              route_control_profiles = optional(list(object({<br>                direction = string<br>                target_dn = string<br>                }<br>              )))<br>            }<br>          )))<br>        }<br>      )))<br>      static_routes = optional(list(object(<br>        {<br>          prefix              = string<br>          fallback_preference = optional(string)<br>          route_control       = optional(bool)<br>          track_policy        = optional(string)<br>          next_hop_addresses = optional(list(object(<br>            {<br>              next_hop_ip           = string<br>              preference            = optional(string)<br>              next_hop_profile_type = optional(string)<br>              track_member          = optional(string)<br>              track_policy          = optional(string)<br><br>            }<br>          )))<br>        }<br>      )))<br>      ospf_interface_profile = optional(object(<br>        {<br>          authentication_key    = optional(string)<br>          authentication_key_id = optional(string)<br>          authentication_type   = optional(string)<br>          ospf_interface_policy = optional(string)<br>          description           = optional(string)<br>          annotation            = optional(string)<br>        }<br>      ))<br>      bgp_peers = optional(list(object(<br>        {<br>          loopback_as_source  = optional(bool)<br>          ip_address          = optional(string)<br>          ipv6_address        = optional(string)<br>          address_control     = optional(list(string))<br>          allowed_self_as_cnt = optional(string)<br>          annotation          = optional(string)<br>          bgp_controls = optional(object(<br>            {<br>              allow_self_as     = optional(bool)<br>              as_override       = optional(bool)<br>              dis_peer_as_check = optional(bool)<br>              nh_self           = optional(bool)<br>              send_com          = optional(bool)<br>              send_ext_com      = optional(bool)<br>            }<br>          ))<br>          alias                  = optional(string)<br>          password               = optional(string)<br>          peer_controls          = optional(list(string))<br>          private_as_control     = optional(list(string))<br>          ebgp_multihop_ttl      = optional(string)<br>          weight                 = optional(string)<br>          as_number              = optional(string)<br>          local_asn              = optional(string)<br>          local_as_number_config = optional(string)<br>          admin_state            = optional(string)<br>          route_control_profiles = optional(list(object({<br>            direction = string<br>            target_dn = string<br>            }<br>          )))<br>        }<br>      )))<br>    }<br><br>  ))</pre> | <pre>[<br>  {<br>    "loopback_as_source": true,<br>    "nodes": []<br>  }<br>]</pre> | no |
| <a name="input_vrf_dn"></a> [vrf\_dn](#input\_vrf\_dn) | Distinguished name of the vrf | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_l3out_dn"></a> [l3out\_dn](#output\_l3out\_dn) | n/a |
<!-- END_TF_DOCS -->