resource "aci_bfd_interface_policy" "bfd" {
  tenant_dn     = aci_tenant.tenant.id
  name          = "bfd_policy"
  admin_st      = "enabled"
  ctrl          = "opt-subif"
  detect_mult   = "3"
  echo_admin_st = "disabled"
  echo_rx_intvl = "50"
  min_rx_intvl  = "50"
  min_tx_intvl  = "50"
}

resource "aci_rest_managed" "bfd_multihop_protocol_profile" {
  dn         = "${aci_tenant.tenant.id}/bfdMhNodePol-test"
  class_name = "bfdMhNodePol"
  content = {
    name       = "test"
    adminSt    = "enabled"
    minRxIntvl = "250"
    minTxIntvl = "250"
    detectMult = "3"
  }
}

resource "aci_rest_managed" "bfd_multihop_interface_profile1" {
  dn         = "${aci_tenant.tenant.id}/bfdMhIfPol-test1"
  class_name = "bfdMhIfPol"
  content = {
    name       = "test1"
    adminSt    = "enabled"
    minRxIntvl = "250"
    minTxIntvl = "250"
    detectMult = "3"
  }
}

resource "aci_rest_managed" "bfd_multihop_interface_profile2" {
  dn         = "${aci_tenant.tenant.id}/bfdMhIfPol-test2"
  class_name = "bfdMhIfPol"
  content = {
    name       = "test2"
    adminSt    = "disabled"
    minRxIntvl = "250"
    minTxIntvl = "250"
    detectMult = "3"
  }
}

resource "aci_bgp_best_path_policy" "best_path_policy" {
  tenant_dn = aci_tenant.tenant.id
  name      = "bgp_path1"
  ctrl      = "asPathMultipathRelax"
}

resource "aci_bgp_timers" "timer" {
  tenant_dn    = aci_tenant.tenant.id
  name         = "timer1"
  gr_ctrl      = "helper"
  hold_intvl   = "189"
  ka_intvl     = "65"
  max_as_limit = "70"
  name_alias   = "aliasing"
  stale_intvl  = "15"
}

resource "aci_match_rule" "rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule"
}

resource "aci_match_rule" "rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule2"
}

resource "aci_match_rule" "rule3" {
  tenant_dn = aci_tenant.tenant.id
  name      = "match_rule3"
}

resource "aci_route_control_profile" "profile1" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile1"
  route_control_profile_type = "global"
}

resource "aci_route_control_profile" "profile2" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile2"
  route_control_profile_type = "global"
}

resource "aci_route_control_profile" "profile3" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile3"
  route_control_profile_type = "global"
}

resource "aci_route_control_profile" "profile4" {
  parent_dn                  = aci_tenant.tenant.id
  name                       = "route_profile4"
  route_control_profile_type = "global"
}

resource "aci_action_rule_profile" "set_rule" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule1"
}

resource "aci_action_rule_profile" "set_rule2" {
  tenant_dn = aci_tenant.tenant.id
  name      = "rule2"
}

resource "aci_rest_managed" "netflow1" {
  dn         = "${aci_tenant.tenant.id}/monitorpol-test1"
  class_name = "netflowMonitorPol"
  content = {
    name = "test1"
  }
}

resource "aci_rest_managed" "netflow2" {
  dn         = "${aci_tenant.tenant.id}/monitorpol-test2"
  class_name = "netflowMonitorPol"
  content = {
    name = "test2"
  }
}
