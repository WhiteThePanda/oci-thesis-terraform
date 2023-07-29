# CREATE ALL RESOURCES
# FILE READING
locals {
    # get json 
    policies_data = jsondecode(file("${path.module}/policies.json"))
    # get all users
    all_policies = [for policy in local.policies_data.policies: policy]
    key_value = file("/home/shanly/.apikeys/shanly_public.pem")
}

# USERS
module "iam_users" {
  source          = "oracle-terraform-modules/iam/oci//modules/iam-user"
  # Pinning each module to a specific version is highly advisable. Please adjust and uncomment the line below
  # version               = "x.x.x"
  tenancy_ocid    = var.tenancy_ocid # required
  users           = [ # a list of users
    { # user1
      name        = "THESIS_USER" # required
      description = "THESIS_USER - terraformed" # required
      email       = "shanly@shanly.fr"
    },
  ]
}

# Generate one time password
# resource "oci_identity_ui_password" "test_ui_password" {
#  user_id = module.iam_users.name_ocid.THESIS_USER
# }

# Generate API keys
# resource "oci_identity_api_key" "user_api_key" {
    #Required
#    key_value = local.key_value
#    user_id = module.iam_users.name_ocid.THESIS_USER
# }

# output "apikey_fingerprint"{
#  value = resource.oci_identity_api_key.user_api_key.fingerprint
# }

# output "password" {
#  value = resource.oci_identity_ui_password.test_ui_password.password
# }

output "user_ocid" {
  value = module.iam_users.name_ocid.THESIS_USER
}

# GROUPS

# Group for users
resource "oci_identity_group" "thesis_users" {
    #Required
    compartment_id = var.tenancy_ocid
    description = "Group for thesis users"
    name = "THESIS_USERS"
}


# Assign user to the group
resource "oci_identity_user_group_membership" "thesis_user_group_membership" {
    #Required
    group_id = resource.oci_identity_group.thesis_users.id
    user_id = module.iam_users.name_ocid.THESIS_USER
}

# TAGS
# tag namespace
resource "oci_identity_tag_namespace" "priv_tags_namespace" {
    #Required
    compartment_id = var.compartment_ocid
    description = "Tag namespace for privileged instances"
    name = "priv-tags"
}

resource "oci_identity_tag" "bucket_tag" {
    #Required
    description = "Tag for bucket access"
    name = "bucket-access"
    tag_namespace_id = resource.oci_identity_tag_namespace.priv_tags_namespace.id
}

# DYNAMIC GROUPS
# Dynamic groups for functions
resource "oci_identity_dynamic_group" "test_dynamic_group" {
    #Required
    compartment_id = var.tenancy_ocid
    description = "Dynamic groups for privileged instances"
    matching_rule = "tag.priv-tags.bucket-access.value"
    name = "bucket-instances"
}

# BUCKETS
resource "oci_objectstorage_bucket" "reports" {
    #Required
    compartment_id = var.compartment_ocid
    name = "thesis-reports"
    namespace = var.namespace
}

# POLICIES 

output "policies" {
    value = local.all_policies
}


resource "oci_identity_policy" "bucket_access_policies" {
    #Required
    compartment_id = var.tenancy_ocid
    description = local.all_policies[0].policy_description
    name = local.all_policies[0].policy_name
    statements = local.all_policies[0].policy_statements
}

resource "oci_identity_policy" "user_tag_access_policies" {
    #Required
    compartment_id = var.tenancy_ocid
    description = local.all_policies[1].policy_description
    name = local.all_policies[1].policy_name
    statements = local.all_policies[1].policy_statements
}

#################################
# CREATE A VCN FOR THE DEV TO USE
#################################

resource "oci_core_virtual_network" "app_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block = "10.1.1.0/24"
  display_name = "app-vcn"
  dns_label = "vcn"
}
resource "oci_core_internet_gateway" "app_igw" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_virtual_network.app_vcn.id
}

resource "oci_core_route_table" "app_rt" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_virtual_network.app_vcn.id
  route_rules {
    destination_type = "CIDR_BLOCK"
    destination = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.app_igw.id
  }
  display_name = "app-rt"
}
resource "oci_core_security_list" "app_sl" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_virtual_network.app_vcn.id
  egress_security_rules {
    stateless="false"
    destination="0.0.0.0/0"
    protocol="all"
  }
  ingress_security_rules {
    stateless="false"
    source="0.0.0.0/0"
    protocol="6"
    tcp_options {
      min=22
      max=22
    }
  }
  display_name = "app-sl"
}

# subnets

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_subnet" "app_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_virtual_network.app_vcn.id
  display_name = "app-subnet"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  cidr_block = oci_core_virtual_network.app_vcn.cidr_block
  route_table_id = oci_core_route_table.app_rt.id
  security_list_ids = [ oci_core_security_list.app_sl.id ]
  prohibit_public_ip_on_vnic = "false"
  dns_label = "appnet"
}


