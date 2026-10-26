# resource "aws_route53_record" "custom_aliases" {
#   for_each = var.r53_custom_aliases
#   zone_id = var.r53_hosted_zone_id
#   name    = each.key
#   type    = "CNAME"
#   ttl     = 60
#   records = each.value
# }
