data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ecr_authorization_token" "token" {}

# data "aws_vpc" "vpc" {
#   filter {
#     name   = "tag:Name"
#     values = ["hub"]
#   }
# }

# data "aws_subnets" "intra_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.vpc.id]
#   }
#   tags = {
#     Name = "intra-*"
#   }
# }

# data "aws_subnets" "private_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.vpc.id]
#   }
#   tags = {
#     Name = "private-*"
#   }
# }