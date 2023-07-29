# oci-thesis-terraform
Source code of attacks and infrastructure used in the thesis

# Usage
In order to use follow the attacks presented in section attack plan:

0 - create a file with this model with your administrator credentials

```
#Terraform administrator
export TF_VAR_tenancy_ocid=
export TF_VAR_user_ocid=
export TF_VAR_fingerprint=
export TF_VAR_region=
export TF_VAR_private_key_path=
export TF_VAR_compartment_ocid=
export TF_VAR_namespace=
```


1 - run the folder 1-setup infra with an admin account by sourcing the file.
```source "path_to_admin_config_file"```

An attacker user will be generated called "THESIS_USER"
Create a config file for the credentials of this user

2 - run one of the scenarios folder with an admin account

3 - run the corresponding attack infrastructure with the developer account
```source "path_to_dev_config_file"```

