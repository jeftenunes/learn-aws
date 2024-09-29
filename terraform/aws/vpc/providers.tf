provider "aws" {
  region = "us-east-1"
  alias  = "zona_a"
}

provider "aws" {
  region = "us-west-2"
  alias  = "zona_b"
}
