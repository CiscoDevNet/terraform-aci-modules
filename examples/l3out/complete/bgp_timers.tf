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
