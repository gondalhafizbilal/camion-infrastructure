resource "aws_route53_zone" "primary" {
  name = "dev.camiontrading.com"
  tags = var.common_tags
}

# data "aws_route53_zone" "primary" {
#   name         = "${var.common_tags.environment}.practicetoolkit.co.uk"
#   private_zone = false
# }

# resource "aws_route53_zone" "private" {
#   name = ""
#   tags = var.common_tags
#   vpc {
#     vpc_id = module.vpc01.id
#   }
# }