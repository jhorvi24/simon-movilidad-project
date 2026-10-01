###############################################################################
# Configuracion de TFLint
# Usa el ruleset de AWS para detectar errores especificos del provider
# (tipos de instancia invalidos, atributos deprecados, etc.).
###############################################################################

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.37.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}
