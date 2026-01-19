terraform {
  backend "s3" {
    bucket         = "cloud-migration-terra-backend"
    key            = "backend/terraform.tfstate" # Path within the bucket
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true                   # Enables native S3 locking
  }
}

provider "aws" {
  region = var.region
}

provider "google" {
  project = "alexandra-fefler-sandbox"
  region  = "us-central1"
}

module "aws" {
  source = "git::https://github.com/sagitab/simple_ec2.git//modules/aws?ref=main"
  #source = "./modules/aws"
  count  = terraform.workspace == "aws" ? 1 : 0
}


module "gcp" {

    source = "git::https://github.com/AlexandraFefler/GCPresources.git?ref=v1.0.1"

    count = terraform.workspace  == "gcp" ? 1 : 0 # if var.cloud is "GCP", create one of this module usage. if not, create 0.
 

    project_id = "alexandra-fefler-sandbox"

    region = "us-central1"

    zone = "us-central1-a"

    app_image = "nginx"

}
output "my_module_path" {
  value = path.module
}