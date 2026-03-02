terraform {
  backend "s3" {
    bucket         = "eks-tfstate-326306382233-us-east-1"
    key            = ("environments/dev/aws-s3-bucket.tfstate")
    region         = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}