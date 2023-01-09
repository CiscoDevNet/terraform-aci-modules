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
