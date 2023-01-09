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
