# ansible-terraform-demos

Ansible collection (`rsoliman.terraform_demos`) containing some roles to demonstrate using ansible to drive a Terraform plan, as well as sample playbooks that call on those roles. 

# Roles in the collection:

terraform_provision_resources
Role used to provision some resources on AWS. Requires the passing of the following parameters as 

# extra_vars:

working_dir_name (has a default value)
tf_plan_file_name (has a default value)
tf_vars_file_name (has a default value)
aws_region
aws_name_tag
aws_ami_id
aws_instance_size
aws_instance_count
terraform_provision_resources
Role that will destroy the resources in AWS. Requires the passing of the following parameters as extra_vars:

working_dir_name (has a default value)
tf_plan_file_name (has a default value)
tf_vars_file_name (has a default value)


Sample Playbooks that use both roles are also provided.