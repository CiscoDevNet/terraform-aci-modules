terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = "2.0.0"
    }
  }
  required_version = "~> 1.1.0"
}

variable "aci_username" {}

variable "aci_password" {}

variable "aci_url" {}

provider "aci" {
  # cisco-aci user name
  username = var.aci_username
  # cisco-aci password
  password = var.aci_password
  # cisco-aci url
  url      = var.aci_url
  insecure = true
}

resource "aci_tenant" "test" {
  name = "tf_test_tn"
}

resource "aci_vrf" "test" {
  name      = "test_vrf"
  tenant_dn = aci_tenant.test.id
}

data "aci_l3_domain_profile" "core" {
  name = "core_l3dom"
}

resource "aci_ospf_interface_policy" "ospf_pol" {
  tenant_dn = aci_tenant.test.id
  name      = "p2p_ospf"
  nw_t      = "p2p"
}








