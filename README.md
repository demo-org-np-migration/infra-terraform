# infra-terraform

Este repo es la infraestructura de Cauri: la plataforma compartida (`platform/`) y
los dos entornos de aplicación (`envs/staging/`, `envs/prod/`). Lo mantenemos
Pablo y yo. Está razonablemente ordenado en módulos, pero no nos engañemos: hay
decisiones tomadas para ir rápido que en algún momento vamos a tener que pagar
(ver "Deuda conocida" al final).

No hay pipeline de `apply`. Todavía aplicamos a mano, mirando el plan. El único
workflow que corre en CI es `terraform fmt -check` + `terraform validate`, para
no mergear algo que ni siquiera parsea.

## Estructura

```
versions.tf          referencia de versiones de providers (no es un root que se aplique)
platform/             la plataforma compartida: Argo, Prometheus, Kafka, Keycloak,
                       Kong, coredns, vendor mocks, el runner de Actions
modules/environment/  todo lo que se repite por entorno: namespace, postgres,
                       redis, secrets, colas, el bucket de KYC
envs/staging/          instancia el módulo con env = staging
envs/prod/             instancia el módulo con env = prod
```

## Cómo aplicar

Orden importa. `platform` tiene que existir antes que los entornos porque
Keycloak, Kafka y Kong viven ahí.

```bash
# 1. platform (una sola vez, o cuando cambia algo compartido)
cd platform
terraform init
terraform plan \
  -var="github_runner_pat=$GITHUB_RUNNER_PAT" \
  -out=tfplan
terraform apply tfplan

# 2. staging
cd ../envs/staging
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 3. prod (recién después de validar staging)
cd ../prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Si `TF_VAR_github_runner_pat` no está seteado, el runner se crea igual y queda
en `CrashLoopBackOff` hasta que le demos un PAT real. Lo dejamos así a
propósito: no vale la pena bloquear el resto del apply por el runner.

Variables que usamos casi siempre por `TF_VAR_*` en vez de `-var`:
`kube_context`, `aws_endpoint`, `vendor_mock_tag`, `gh_runner_tag`,
`github_runner_pat`.

## Puertos en la laptop

k3d mapea estos puertos del cluster a la laptop. Lo dejo acá para no tener que
repetirlo en Slack cada dos semanas:

| Puerto laptop | Qué es |
|---|---|
| `8443` | Argo CD (HTTPS) |
| `8180` | Keycloak (el issuer real de los tokens sigue siendo `keycloak.platform.svc:8080`, no toques eso) |
| `8000` | Kong (proxy) |
| `3000` | Grafana |
| `4566` | LocalStack (S3, SQS, DynamoDB) |

## State

Backend S3 contra LocalStack: bucket `cauri-terraform-state`, lock en DynamoDB
`terraform-locks`. El bucket y la tabla los crea el bootstrap del lab, no
nosotros -- si `terraform init` te dice que no encuentra el bucket, es que
falta correr el bootstrap, no que este repo esté roto.

Cada raíz tiene su propio state (`platform/terraform.tfstate`,
`envs/staging/terraform.tfstate`, `envs/prod/terraform.tfstate`). Los
endpoints del backend están hardcodeados a `http://localhost:4566` porque un
bloque `backend` no acepta variables ni expresiones. El día que esto corra
contra algo que no sea la laptop, se pisan con `-backend-config` en el init.

## Deuda conocida

- **Keycloak en modo dev** (`start-dev`). Sirve para levantar rápido con
  realms importados, pero no es apto para producción real: sin clustering,
  sin cache distribuida, hostname strict apagado. Ojo con `KC_HOSTNAME`:
  Keycloak 25 usa hostname v2, así que le pasamos la URL completa
  (`http://keycloak.platform.svc:8080`) en vez de solo el host -- con v2,
  `KC_HOSTNAME_PORT` y `KC_HOSTNAME_STRICT_HTTPS` ni existen (son de v1) y si
  le dejás solo el host, el issuer arrastra el puerto por el que entró el
  request (te queda `:8180` pidiendo desde la laptop, y los servicios
  rechazan esos tokens porque no matchea `KEYCLOAK_ISSUER`). Además sigue en
  H2 (persistido en un PVC en `/opt/keycloak/data/h2` para que un restart del
  pod no le pierda las claves RSA del realm) en vez de Postgres -- en serio
  iría contra una base real como el resto de los servicios.
- **Kafka single node** (KRaft, un solo broker). Si se cae, se cae para
  staging y para prod a la vez porque comparten broker. Lo sabemos, no es
  el momento de meter 3 nodos para un cluster de laptop.
- **El bucket de KYC es público** (`cauri-<env>-kyc-documents`, ACL
  `public-read`). Fue un pedido de risk: Veridoc necesita poder leer el
  documento por URL directa sin que nosotros le demos credenciales de AWS.
  No me termina de cerrar pero está decidido arriba mío -- si alguien lo
  quiere revisar, que hable con risk antes de tocar `s3.tf`.
- **Un solo Kong para los dos entornos**, ruteo por host. Si Kong se cae, se
  caen los dos. Alternativa sería un Kong por entorno, pero es más infra que
  mantener por ahora.

## Troubleshooting rápido

- `terraform validate` falla con "backend initialization required": corré
  `terraform init -backend=false` si solo querés validar sintaxis sin tocar
  el state real.
- Si el runner no toma jobs, mirá el Secret `gh-runner-token` en `platform` --
  probablemente el PAT venció (dura poco) o nunca se seteó.
- Los vendor mocks responden todos igual salvo por `VENDOR`/`MODE`; si un
  mock no contesta la ruta que esperás, es porque esa ruta no está en
  `platform/vendor-mocks/server.js` todavía, no un bug de red.
- Para probar un mock sin pasar por k8s: `cd platform/vendor-mocks && VENDOR=sentinel
  MODE=live PORT=8080 node server.js`, y en otra terminal `curl -X POST
  localhost:8080/v2/assess -d '{"amount":"150000"}'` -- debería devolver
  `risk: 0.9`.
