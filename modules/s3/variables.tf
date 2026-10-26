variable "bucket_name" {
  type = string
}

variable "lifecycle_delete" {
  type    = bool
  default = false
}
variable "lifecycle_retain" {
  type    = bool
  default = false
}
variable "retain_days" {
  type    = number
  default = 60
}

variable "delete_days" {
  type    = number
  default = 30
}

variable "block_public_access" {
  type    = bool
  default = true
}

variable "acl" {
  type    = string
  default = "private"
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" {
  default = {}
  type    = map(any)
}

variable "kms_key_arn" {
  description = "If Key Declared will default to KMS encryption"
  type        = string
  default     = null
}

variable "access_logs_bucket" {
  description = "True if s3 Bucket will be used as a LB access log"
  type        = string
  default     = false
}

variable "elb_push_account_id" {
  type = map(any)
  default = {
    "us-east-1"       = "127311923021"
    "us-east-2"       = "033677994240"
    "us-west-1"       = "027434742980"
    "us-west-2"       = "797873946194"
    "af-south-1"      = "098369216593"
    "ca-central-1"    = "985666609251"
    "eu-central-1"    = "054676820928"
    "eu-west-1"       = "156460612806"
    "eu-west-2"       = "652711504416"
    "eu-south-1"      = "635631232127"
    "eu-west-3"       = "009996457667"
    "eu-north-1"      = "897822967062"
    "ap-east-1"       = "754344448648"
    "ap-northeast-1"  = "582318560864"
    "ap-northeast-2"  = "600734575887"
    "ap-northeast-3"  = "383597477331"
    "ap-southeast-1"  = "114774131450"
    "ap-southeast-2"  = "783225319266"
    "ap-south-1"      = "718504428378"
    "me-south-1"      = "076674570225"
    "sa-east-1"       = "507241528517"
    "us-gov-west-1*"  = "048591011584"
    "us-gov-east-1*"  = "190560391635"
    "cn-north-1*"     = "638102146993"
    "cn-northwest-1*" = "037604701340"
  }
}

variable "versioning" {
  description = "Enable S3 bucket versioning"
  default     = false
  type        = bool
}

variable "mfa_delete" {
  description = "Enable MFA delete for S3 bucket versioning"
  default     = false
  type        = bool
  
}

variable "cors_configuration" {
  description = "CORS configuration for the S3 bucket"
  type        = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default     = []
}
