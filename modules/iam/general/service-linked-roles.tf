resource "aws_iam_service_linked_role" "autoscaling" {
  aws_service_name = "autoscaling.amazonaws.com"
}

# resource "aws_iam_service_linked_role" "rds" {
#   aws_service_name = "rds.amazonaws.com"
# }

resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}
