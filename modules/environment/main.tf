# Este módulo se instancia una vez por entorno (envs/staging, envs/prod). No
# declara providers propios: los hereda de la raíz que lo llama.

locals {
  common_labels = {
    "app.kubernetes.io/part-of" = "cauri"
    "cauri.io/team"             = "platform"
    "cauri.io/env"              = var.env
  }
}
