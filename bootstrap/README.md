# Bootstrap del estado remoto

Este stack crea los buckets de S3 que almacenan el estado remoto de Terraform,
uno por ambiente (`dev` y `prod`). Se ejecuta **una sola vez** y con **estado
local** (no tiene backend remoto, porque es el que crea la infraestructura del
backend).

## Que crea

Por cada ambiente (`dev`, `prod`):

- Bucket S3 `simon-movilidad-tfstate-<env>-<account_id>`
- Versionado habilitado
- Cifrado en reposo con KMS (SSE-KMS)
- Bloqueo total de acceso publico
- Ownership `BucketOwnerEnforced` (sin ACLs)
- Politica que deniega trafico sin TLS

El bloqueo de estado usa el **lockfile nativo de S3** (`use_lockfile = true` en
el backend), disponible desde Terraform >= 1.10. **No se usa DynamoDB.**

## Como ejecutarlo

Necesitas credenciales de AWS con permisos para crear buckets S3 (solo para este
paso inicial; el resto del ciclo de vida usa OIDC desde GitHub Actions).

```bash
cd bootstrap

terraform init
terraform plan
terraform apply
```

Al terminar, anota los nombres de los buckets que aparecen en el output
`state_bucket_names`. Deberian coincidir con los que ya estan referenciados en
`env/dev/backend.tf` y `env/prod/backend.tf`.

## Importante

- El recurso `aws_s3_bucket` tiene `prevent_destroy = true`. Si necesitas
  eliminarlo de verdad, primero quita ese lifecycle y luego destruye.
- Guarda el `terraform.tfstate` local de este bootstrap en un lugar seguro
  (o subelo manualmente a un bucket), ya que no vive en backend remoto.
