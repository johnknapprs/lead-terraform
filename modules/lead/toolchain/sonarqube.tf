resource "random_string" "sonarqube_db_password" {
  length  = 10
  special = false
}

resource "random_string" "sonar_jenkins_password" {
  length  = 10
  special = false
}

data "template_file" "sonarqube_values" {
  template = file("${path.module}/sonarqube-values.tpl")
}

resource "helm_release" "sonarqube" {
  count      = var.enable_sonarqube ? 1 : 0
  repository = "stable"
  name       = "sonarqube"
  namespace  = module.toolchain_namespace.name
  chart      = "sonarqube"
  version    = "2.0.0"
  timeout    = 1200
  wait       = true

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set_sensitive {
    name  = "postgresql.postgresPassword"
    value = random_string.sonarqube_db_password.result
  }

  values = [data.template_file.sonarqube_values.rendered]
}

resource "kubernetes_secret" "jenkins_sonar" {
  metadata {
    name      = "jenkins-sonarqube-credential"
    namespace = module.toolchain_namespace.name

    labels = {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
      "jenkins.io/credentials-type"  = "usernamePassword"
    }
  }

  type = "Opaque"

  data = {
    #    username = "jenkins"
    #    password = "${random_string.sonar_jenkins_password.result}"
    username = "admin"
    password = "admin"
  }
}
