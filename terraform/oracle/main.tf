terraform {
  required_version = ">= 1.5.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.40"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Always-Free ARM Ampere A1 image lookup (Canonical Ubuntu 22.04 aarch64).
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "hermes" {
  compartment_id = var.compartment_ocid
  display_name   = "hermes-anywhere-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "hermesvcn"
}

resource "oci_core_internet_gateway" "hermes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.hermes.id
  display_name   = "hermes-igw"
  enabled        = true
}

resource "oci_core_route_table" "hermes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.hermes.id
  display_name   = "hermes-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.hermes.id
  }
}

resource "oci_core_security_list" "hermes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.hermes.id
  display_name   = "hermes-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  dynamic "ingress_security_rules" {
    for_each = var.ssh_allowed_cidrs
    content {
      protocol = "6" # TCP
      source   = ingress_security_rules.value
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.dashboard_allowed_cidrs
    content {
      protocol = "6"
      source   = ingress_security_rules.value
      tcp_options {
        min = 9119
        max = 9119
      }
    }
  }
}

resource "oci_core_subnet" "hermes" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.hermes.id
  display_name      = "hermes-subnet"
  cidr_block        = "10.0.1.0/24"
  route_table_id    = oci_core_route_table.hermes.id
  security_list_ids = [oci_core_security_list.hermes.id]
  dns_label         = "hermessubnet"
}

resource "oci_core_instance" "hermes" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.hermes.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/../../cloud-init/hermes.cloud-config.yaml.tpl", {
      hermes_version         = var.hermes_version
      openrouter_api_key     = var.openrouter_api_key
      telegram_bot_token     = var.telegram_bot_token
      telegram_allowed_users = var.telegram_allowed_users
      repo_owner             = var.repo_owner
      repo_name              = var.repo_name
    }))
  }
}
