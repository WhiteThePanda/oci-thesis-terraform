

locals {
    # get json 
    filename = var.policy_file_number == "1" ? "1-policies_compute.json" : (var.policy_file_number == "2" ? "2-policies_serverless.json" : "") 
    policies_data = jsondecode(file("${path.module}/${local.filename}"))
    # get all users
    all_policies = [for policy in local.policies_data.policies: policy]
    key_value = file("/home/shanly/.apikeys/shanly_public.pem")
}

resource "oci_identity_policy" "policy_statements" {
    count = length(local.all_policies)
    compartment_id = var.tenancy_ocid
    description = local.all_policies[count.index].policy_description
    name = local.all_policies[count.index].policy_name
    statements = local.all_policies[count.index].policy_statements
}