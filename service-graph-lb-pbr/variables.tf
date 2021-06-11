variable "tenant" {
    description = "ACI Tenant information"
    type        = map
    default     = {
        name        = "terraform-lb-tenant"
        description = "This tenant is created by the ACI terraform service-graph-lb module."
    }
}

variable "vrf" {
    description = "ACI VRF information"
    type        = map
    default     = {
        name        = "terraform-lb-vrf"
        description = "This VRF is created by the ACI terraform service-graph-lb module."
    }
}

variable "provider_bd" {
    description = "ACI Provider BD information"
    type        = map
    default     = {
        name              = "terraform-lb-provider-bd"
        description       = "This BD is created as the provider BD by the ACI terraform service-graph-lb module."
        multi_dst_pkt_act = "bd-flood"
    }
}

variable "provider_bd_subnets" {
    description = "ACI Provider BD subnets information"
    type        = map
    default     = {
        subnet_1 = {
            subnet      = "10.10.101.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb module."
        },
        subnet_2 = {
            subnet      = "10.10.102.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb module."
        }
    }
}

variable "consumer_bd" {
    description = "ACI Consumer BD information"
    type        = map
    default     = {
        name              = "terraform-lb-consumer-bd"
        description       = "This BD is created as the consumer BD by the ACI terraform service-graph-lb module."
        multi_dst_pkt_act = "bd-flood"
    }
}

variable "consumer_bd_subnets" {
    description = "ACI Consumer BD subnets information"
    type        = map
    default     = {
        subnet_1 = {
            subnet      = "10.10.103.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb module."
        },
        subnet_2 = {
            subnet      = "10.10.104.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb module."
        }
    }
}

variable "provider_service_bd" {
    description = "ACI Provider Service BD information"
    type        = map
    default     = {
        name              = "terraform-lb-provider-service-bd"
        description       = "This BD is created as the provider service BD by the ACI terraform service-graph-lb-pbr module."
        multi_dst_pkt_act = "bd-flood"
    }
}

variable "provider_service_bd_subnets" {
    description = "ACI Provider Service BD subnets information"
    type        = map
    default     = {
        subnet_1 = {
            subnet      = "10.10.105.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb-pbr module."
        }
    }
}

variable "consumer_service_bd" {
    description = "ACI Consumer Service BD information"
    type        = map
    default     = {
        name              = "terraform-lb-consumer-service-bd"
        description       = "This BD is created as the consumer service BD by the ACI terraform service-graph-lb-pbr module."
        multi_dst_pkt_act = "bd-flood"
    }
}

variable "consumer_service_bd_subnets" {
    description = "ACI Consumer Service BD subnets information"
    type        = map
    default     = {
        subnet_1 = {
            subnet      = "10.10.106.1/24"
            description = "This BD Subnet is created by the ACI terraform service-graph-lb-pbr module."
        }
    }
}

variable "filters" {
    description = "Create filters with these names and ports"
    type        = map
    default     = {
        filter_any = {
            filter      = "any",
            entry       = "any",
            description = "This any filter is created by the ACI terraform service-graph-lb module."
        }
    }
}

    variable "contract" {
    description = "Create contract with these filters"
    type        = map
    default     = {
        name        = "any",
        subject     = "any",
        description = "This any contract is created by the ACI terraform service-graph-lb module.",
        scope       = "tenant"
    }
}

variable "ap" {
    description = "Create application profile"
    type        = map
    default     = {
        name        = "terraform-lb-anp",
        description = "This Application Profile is created by the ACI terraform service-graph-lb module."
    }
}

variable "epgs" {
    description = "Create epgs"
    type        = map
    default     = {
        consumer = {
            name        = "terraform-lb-consumer-epg",
            encap       = "21"
            description = "Consumer EPG created by the ACI terraform service-graph-lb module."
        },
        provider = {
            name        = "terraform-lb-provider-epg",
            encap       = "22"
            description = "Provider EPG created by the ACI terraform service-graph-lb module."
        }
    }
}

variable "vmm_provider_dn" {
    description = "VMM Provider DN"
    type        = string
    default     = "uni/vmmp-VMware"
}

variable "vmm_domain_name" {
    description = "VMM Domain name"
    type        = string
}

variable "vmm_controller_name" {
    description = "VMM Controller name"
    type        = string
}

variable "annotation" {
    description = "ACI Annotation string used for REST calls"
    type        = string
    default     = "orchestrator:terraform"
}

variable "device_name" {
    description = "ACI L4-L7 Device name"
    type        = string
    default     = "BIGIP-VE-Standalone"
}

variable "device_ip_address" {
    description = "ACI L4-L7 Device IP Address"
    type        = string
}

variable "device_mac_address" {
    description = "ACI L4-L7 Device MAC Address"
    type        = string
    default     = "00:00:00:00:00:00"
}

variable "vm_name" {
    description = "Load Balancer VM name"
    type        = string
    default     = "BIGIP-VE-Standalone"
}

variable "vnic" {
    description = "VM VNICs used for service graph"
    type        = map
    default     = {
        internal = "Network adapter 3",
        external = "Network adapter 2"
    }
}

variable "service_graph" {
    description = "Create service graph"
    type        = map
    default     = {
        name        = "2ARM-template",
        description = "This Service Graph is created by the ACI terraform service-graph-lb module."
    }
}

variable "ip_sla_name" {
    description = "ACI L4-L7 IP SLA Monitoring Policy name"
    type        = string
    default     = "BIGIP-VE-Standalone-ICMP-IPSLA-MonPol"
}

variable "health_group_name" {
    description = "ACI L4-L7 Health Group name"
    type        = string
    default     = "BIGIP-VE-Standalone-Health-Group"
}
