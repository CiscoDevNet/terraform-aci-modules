resource "aci_contract" "contract1" {
  tenant_dn = "uni/tn-common"
  name      = "contract1"
  scope     = "global"
}

resource "aci_contract_subject" "contract_subject1" {
  contract_dn   = aci_contract.contract1.id
  name          = "contract_subject1"
  rev_flt_ports = "no"
}

resource "aci_filter" "filter1" {
  tenant_dn   = "uni/tn-common"
  name        = "filter1"
  description = "This filter is created by terraform ACI provider."
}

resource "aci_filter_entry" "entry1" {
  filter_dn     = aci_filter.filter1.id
  name          = "entry1"
  description   = "This entry is created by terraform ACI provider"
  apply_to_frag = "no"
  arp_opc       = "unspecified"
  d_from_port   = "80"
  d_to_port     = "80"
  ether_t       = "ip"
  icmpv4_t      = "unspecified"
  icmpv6_t      = "unspecified"
  match_dscp    = "AF11"
  prot          = "tcp"
  s_from_port   = "80"
  s_to_port     = "443"
  stateful      = "no"
  tcp_rules     = ["ack"]
}

resource "aci_contract_subject_filter" "contract_subject_filter1" {
  contract_subject_dn = aci_contract_subject.contract_subject1.id
  action              = "permit"
  directives          = ["log"]
  priority_override   = "default"
  filter_dn           = aci_filter.filter1.id
}
