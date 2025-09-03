provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-up-n-running-20250820"  # S3 bucket for remote state
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"  # Path to database state file
  instance_type = "t2.micro"
  min_size     = 2
  max_size     = 2
}