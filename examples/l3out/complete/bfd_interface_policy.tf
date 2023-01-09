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
