
resource "aws_ecr_repository" "images" {

  for_each = toset(var.image_names)
  name                 = format("repo-%s-image", each.value)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}

