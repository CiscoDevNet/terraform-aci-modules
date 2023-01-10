resource "aci_l3_domain_profile" "profile" {
  name = "l3_domain_profile"
}

resource "aci_physical_domain" "physical_domain" {
  name = "PhysDom"
}
