
terraform {
  backend "s3" {
    bucket = "terraform-eks-cicd-2112"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
