resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "vrf1"
}

resource "aci_rest_managed" "vrf_fallback_route_group1" {
  dn         = "${aci_vrf.vrf.id}/fbrg-fallback_grp_1"
  class_name = "fvFBRGroup"
  content = {
    name = "fallback_grp_1"
  }
  child {
    rn         = "pfx-[10.1.1.2/24]"
    class_name = "fvFBRoute"
    content = {
      fbrPrefix = "10.1.1.2/24"
    }
  }
  child {
    rn         = "nexthop-[10.1.1.3]"
    class_name = "fvFBRMember"
    content = {
      rnhAddr = "10.1.1.3"
    }
  }
}

resource "aci_rest_managed" "vrf_fallback_route_group2" {
  dn         = "${aci_vrf.vrf.id}/fbrg-fallback_grp_2"
  class_name = "fvFBRGroup"
  content = {
    name = "fallback_grp_2"
  }
  child {
    rn         = "pfx-[11.1.1.2/24]"
    class_name = "fvFBRoute"
    content = {
      fbrPrefix = "11.1.1.2/24"
    }
  }
  child {
    rn         = "nexthop-[11.1.1.3]"
    class_name = "fvFBRMember"
    content = {
      rnhAddr = "11.1.1.3"
    }
  }
}
