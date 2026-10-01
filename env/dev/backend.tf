###############################################################################
# Backend remoto del ambiente DEV
#
# Estado en S3 con bloqueo NATIVO (use_lockfile = true), sin DynamoDB.
# El bucket lo crea el stack bootstrap/. Reemplaza <ACCOUNT_ID> por el ID real
# de tu cuenta (o configuralo via -backend-config en el init del pipeline).
###############################################################################

terraform {
  backend "s3" {
    bucket       = "simon-movilidad-tfstate-dev-001239102331"
    key          = "ecs-app/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
