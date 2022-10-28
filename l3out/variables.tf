terraform {
  experiments = [module_variable_optional_attrs]
}

variable "tenant_dn" {
  type = string
}

variable "name" {
  type = string
}

variable "alias" {
  type    = string
  default = ""
}

variable "annotation" {
  type    = string
  default = "orchestrator:terraform"
}

variable "description" {
  default = ""
}

variable "vrf_dn" {
  type    = string
  default = ""
}

variable "l3_domain_dn" {
  type    = string
  default = ""
}

variable "route_profile_for_interleak_dn" {
  type    = string
  default = ""
}

variable "route_control_for_dampening" {
  type = object({
    address_family = optional(string) # choose between ipv4 and v6
    route_map_dn   = optional(string)
  })
  validation {
    condition     = contains(["ipv4", "ipv6"], var.route_control_for_dampening.address_family)
    error_message = "Invalid Value!"
  }
}

variable "route_control_enforcement" {
  type = bool
}

variable "target_dscp" {
  type    = string
  default = "unspecified"
  validation {
    condition = contains(
      ["CS0",
        "CS1",
        "AF11",
        "AF12",
        "AF13",
        "CS2",
        "AF21",
        "AF22",
        "AF23",
        "CS3",
        "CS4",
        "CS5",
        "CS6",
        "CS7",
        "AF31",
        "AF32",
        "AF33",
        "AF41",
        "AF42",
        "AF43",
        "VA",
        "EF",
    "unspecified"], var.target_dscp)
    error_message = "Invalid Value!"
  }
}

############## Variables for  "aci_l3out_bgp_external_policy" ####################    
variable "external_bgp_name_alias" {
  default = ""
}

############## Variables for  "aci_l3out_external_epg" ####################
variable "l3out_external_epg" {
  type = list(object({
    annotation             = optional(string)
    description            = optional(string)
    exception_tag          = optional(string)
    flood_on_encapsulation = optional(string)
    label_match_criteria   = optional(string)
    alias                  = optional(string)
    name                   = string
    preferred_group_member = optional(bool)
    qos_class              = optional(string)
    target_dscp            = optional(string)
    subnets = optional(list(object({
      ip        = string
      aggregate = optional(string)
      alias = optional(string)
      scope = list(string)
    })))
  }))
  validation {
    condition = contains(["All", "AtleastOne", "AtmostOne", "None"], var.l3out_external_epg[0].label_match_criteria) && contains(["unspecified", "level6", "level5", "level4", "level3", "level2", "level1", ], var.l3out_external_epg[0].qos_class) && contains(
      ["CS0",
        "CS1",
        "AF11",
        "AF12",
        "AF13",
        "CS2",
        "AF21",
        "AF22",
        "AF23",
        "CS3",
        "CS4",
        "CS5",
        "CS6",
        "CS7",
        "AF31",
        "AF32",
        "AF33",
        "AF41",
        "AF42",
        "AF43",
        "VA",
        "EF",
    "unspecified"], var.l3out_external_epg[0].target_dscp)
    error_message = "Invalid Values!"
  }
}