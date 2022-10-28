locals {
  external_epg_subnets = (flatten([
    for external_epg in var.l3out_external_epg : [
      # ext = external_epg == "subnets" ? [
      for subnet in external_epg.subnets : {
        external_epg_name  = external_epg.name
        subnet_placeholder = "${external_epg.name}_${subnet.ip}!"
        subnet             = concat([external_epg.name], [subnet])
  }]]))
}

resource "aci_l3_outside" "l3out" {
  tenant_dn                       = var.tenant_dn
  name                            = var.name
  name_alias                      = var.alias
  description                     = var.description
  annotation                      = var.annotation
  enforce_rtctrl                  = var.route_control_enforcement == true ? ["export", "import"] : ["export"]
  target_dscp                     = var.target_dscp
  relation_l3ext_rs_ectx          = var.vrf_dn
  relation_l3ext_rs_l3_dom_att    = var.l3_domain_dn != "" ? "${var.l3_domain_dn}" : ""
  relation_l3ext_rs_interleak_pol = var.route_profile_for_interleak_dn != "" ? "${var.route_profile_for_interleak_dn}" : ""
  relation_l3ext_rs_dampening_pol {
    af                     = "${var.route_control_for_dampening.address_family}-ucast"
    tn_rtctrl_profile_name = var.route_control_for_dampening.route_map_dn
  }
}

resource "aci_l3out_bgp_external_policy" "external_bgp" {
  l3_outside_dn = aci_l3_outside.l3out.id
  annotation    = var.annotation
  name_alias    = var.external_bgp_name_alias
}

resource "aci_external_network_instance_profile" "l3out_external_epgs" {
  for_each       = { for ext_epg in var.l3out_external_epg : ext_epg.name => ext_epg }
  l3_outside_dn  = aci_l3_outside.l3out.id
  annotation     = each.value.annotation
  description    = each.value.description
  exception_tag  = each.value.exception_tag
  flood_on_encap = each.value.flood_on_encapsulation
  match_t        = each.value.label_match_criteria
  name_alias     = each.value.alias
  name           = each.value.name
  pref_gr_memb   = each.value.preferred_group_member == true ? "include" : "exclude"
  prio           = each.value.qos_class
  target_dscp    = each.value.target_dscp
}

output "subnets" {
  value = local.external_epg_subnets
}

resource "aci_l3_ext_subnet" "external_epg_subnets" {
  for_each                             = { for subnet in local.external_epg_subnets : subnet.subnet_placeholder => subnet }
  external_network_instance_profile_dn = aci_external_network_instance_profile.l3out_external_epgs[each.value.subnet[0]].id
  ip                                   = each.value.subnet[1].ip
  scope                                = each.value.subnet[1].scope
  aggregate                            = each.value.subnet[1].aggregate

}