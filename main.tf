provider "aws" {
  region = var.region
}

provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1"
}

module "aws" {
  source = "./modules/aws"
  count  = var.cloud == "aws" ? 1 : 0
}
module "gcp" {
  source = "./modules/gcp"
  count  = var.cloud == "aws" ? 1 : 0
}
