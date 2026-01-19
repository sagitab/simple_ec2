provider "aws" {
  region = var.region
}

provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1"
}

module "aws" {
  source = "git::https://github.com/sagitab/simple_ec2.git//modules/aws?ref=main"
  count  = var.cloud == "aws" ? 1 : 0
}
module "gcp" {
  source = "./modules/gcp"
  count  = var.cloud == "aws" ? 1 : 0
}
