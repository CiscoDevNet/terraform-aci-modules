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
