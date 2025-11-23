Terraform module to provision an EC2 instance and bootstrap the repository.

Usage

1. Edit `terraform/terraform.tfvars` (copy `terraform.tfvars.example`) and set `key_name` and `repo_url`.
2. From `terraform/` run:

   terraform init
   terraform apply -var-file=environments/dev.tfvars

Notes

- The user-data installs Java 8, Maven, Git and Tomcat, builds the project and deploys the `webapp` module WAR to Tomcat's ROOT.
- Make sure the key pair you specify exists in the AWS region.
- For production use, tighten security group CIDR and configure IAM instance profile if needed.
