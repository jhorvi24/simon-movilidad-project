# Bootstrap: estado remoto + roles de deploy OIDC

Este stack crea la capa fundacional **por cuenta de AWS**, que es barata (solo
S3 + IAM, sin computo) y se ejecuta **una sola vez** con estado local:

1. **Buckets de estado S3** (uno por ambiente: dev y prod) con versionado,
   cifrado KMS, bloqueo de acceso publico y TLS obligatorio.
2. **Roles de deploy OIDC** para GitHub Actions (dev y prod), via el modulo
   `github-oidc-role`.

## Por que los roles de deploy viven aqui (y no en env/dev, env/prod)

El rol que el pipeline asume es **identidad**, no infraestructura de app. Si
viviera en los stacks de `env/`, crear la "llave" del pipeline obligaria a
aprovisionar toda la VPC/ECS/ALB (costoso) solo para tener un rol de IAM.

Separandolo aqui:

- Corres el bootstrap una vez -> quedan los buckets y los 2 roles de deploy.
  **No se crea computo ni se genera costo recurrente.**
- El pipeline, con esos roles, crea TODA la infra de dev y prod por si mismo.
- Nunca aprovisionas infra de app a mano.

El **OIDC provider** de GitHub ya existe en la cuenta; aqui se referencia por su
ARN deterministico, no se crea (para no chocar con el existente).

## Como ejecutarlo

Requiere credenciales de AWS con permisos para crear S3 e IAM (solo para este
paso inicial).

```bash
cd bootstrap

terraform init
terraform apply
```

Outputs utiles:

- `state_bucket_names` -> nombres de los buckets (ya referenciados en los
  `env/*/backend.tf`).
- `deploy_role_dev_arn` / `deploy_role_prod_arn` -> ARNs de los roles que el
  workflow asume (`role-to-assume`). Deben ser
  `simon-movilidad-dev-gha-deploy` y `simon-movilidad-prod-gha-deploy`.

## Despues del bootstrap

1. En GitHub: secret `AWS_ACCOUNT_ID` y Environments `dev` y `prod`
   (prod con required reviewers).
2. Push a `main` -> el pipeline despliega dev y prod usando los roles creados
   aqui. No vuelves a correr Terraform a mano.

## Importante

- `aws_s3_bucket` tiene `prevent_destroy = true`. Para eliminarlo de verdad,
  primero quita ese lifecycle.
- Guarda el `terraform.tfstate` local de este bootstrap en lugar seguro, ya que
  no vive en backend remoto.
- Define `github_repository` en `terraform.tfvars` (ya incluido).
