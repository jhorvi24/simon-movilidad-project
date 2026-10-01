###############################################################################
# Backend remoto del ambiente PROD
#
# Estado en S3 con bloqueo NATIVO (use_lockfile = true), sin DynamoDB.
# El bucket lo crea el stack bootstrap/. Reemplaza ACCOUNT_ID por el ID real
# de tu cuenta (o configuralo via -backend-config en el init del pipeline).
###############################################################################

terraform {
  backend "s3" {
    bucket       = "simon-movilidad-tfstate-prod-ACCOUNT_ID"
    key          = "ecs-app/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
