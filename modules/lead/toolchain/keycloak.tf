data "template_file" "keycloak_values" {
  template = file("${path.module}/keycloak-values.tpl")

  vars = {
    ssl_redirect     = var.root_zone_name == "localhost" ? false : true
    cluster_domain   = "${var.cluster}.${var.root_zone_name}"
    ingress_hostname = "keycloak.${module.toolchain_namespace.name}.${var.cluster}.${var.root_zone_name}"
  }
}

resource "kubernetes_secret" "keycloak_admin" {
  count = var.enable_keycloak ? 1 : 0
  metadata {
    name      = "keycloak-admin-credential"
    namespace = module.toolchain_namespace.name
  }
  type = "Opaque"

  data = {
    username = "keycloak"
    password = var.keycloak_admin_password
  }
}

resource "helm_release" "keycloak" {
  count      = var.enable_keycloak ? 1 : 0
  depends_on = [helm_release.mailhog]
  repository = data.helm_repository.codecentric.metadata[0].name
  name       = "keycloak"
  namespace  = module.toolchain_namespace.name
  chart      = "keycloak"
  version    = "5.0.1"
  timeout    = 1200

  values = [data.template_file.keycloak_values.rendered]
}


# while using client credentials is preferred, it would require initial client creation using the 
# old realm import method, so just use password based setup since that is known prior to keycloak 
# resource
provider "keycloak" {
  client_id     = "admin-cli"
  username      = "keycloak"
  password      = var.keycloak_admin_password
  url           = "${local.protocol}://keycloak.${module.toolchain_namespace.name}.${var.cluster}.${var.root_zone_name}"
  initial_login = false
}

# Give Keycloak API a chance to become responsive
resource "null_resource" "keycloak_realm_delay" {
  count      = var.enable_keycloak ? 1 : 0  
  depends_on = [helm_release.keycloak]
  
  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "keycloak_realm" "realm" {
  count         = var.enable_keycloak ? 1 : 0
  depends_on    = [helm_release.keycloak, null_resource.keycloak_realm_delay]
  realm         = module.toolchain_namespace.name
  enabled       = true
  display_name  = title(module.toolchain_namespace.name)

  registration_allowed            = true
  registration_email_as_username  = true
  reset_password_allowed          = true
  remember_me                     = true
  verify_email                    = true
  login_with_email_allowed        = true
  duplicate_emails_allowed        = false

  smtp_server {
    host              = "mailhog"
    port              = "1025"
    from              = "keycloak@${module.toolchain_namespace.name}.${var.cluster}.${var.root_zone_name}"
    from_display_name = "Keycloak - ${title(module.toolchain_namespace.name)}"
  }
}
