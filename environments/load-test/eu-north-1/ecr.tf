module "k6_runner_ecr" {
  source               = "cloudposse/ecr/aws"
  name                 = "k6-runner-repo"
  image_tag_mutability = "MUTABLE"
  scan_images_on_push  = true
  tags                 = var.common_tags
}
