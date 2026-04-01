resource "aws_s3_bucket" "devops_project" {
  bucket = "terraform-eks-cicd-2112"

  tags = {
    Name        = "terraform-eks-cicd-2112"
  }
}