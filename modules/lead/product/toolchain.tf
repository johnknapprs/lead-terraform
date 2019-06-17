resource "random_string" "jenkins_admin_password" {
  length  = 10
  special = false
}

data "template_file" "jenkins_values" {
  template = "${file("${path.module}/jenkins-values.tpl")}"

  vars = {
    ingress_hostname = "jenkins.${module.toolchain_namespace.name}.${var.cluster}.${var.root_zone_name}"
    namespace        = "${module.toolchain_namespace.name}"
    logstash_url     = "http://lead-dashboard-logstash.${module.toolchain_namespace.name}.svc.cluster.local:9000"
    slack_team       = "liatrio"
  }
}

module "toolchain_namespace" {
  source     = "../../common/namespace"
  namespace  = "${var.product_name}-toolchain"
  issuer_type = "${var.issuer_type}"
  annotations {
    name  = "${var.product_name}-toolchain"
    cluster = "${var.cluster}"
    "opa.lead.liatrio/ingress-whitelist" = "*.${var.product_name}-toolchain.${var.cluster}.${var.root_zone_name}"
    "opa.lead.liatrio/image-whitelist" = "${var.image_whitelist}"
  }

  providers {
    helm = "helm.toolchain"
    kubernetes = "kubernetes.toolchain"
  }
}

resource "helm_release" "jenkins" {
  provider  = "helm.toolchain"
  name      = "jenkins"
  chart     = "stable/jenkins"
  namespace = "${module.toolchain_namespace.name}"
  timeout   = "300"

  set_sensitive {
    name  = "master.adminPassword"
    value = "${random_string.jenkins_admin_password.result}"
  }

  values = ["${data.template_file.jenkins_values.rendered}"]
}

// Create Jenkins service account
resource "kubernetes_service_account" "jenkins" {
  provider  = "kubernetes.toolchain"
  metadata {
    name      = "jenkins"
    namespace = "${module.toolchain_namespace.name}"

    labels {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations {
      description = "Service account for Jenkins"
      source-repo = "https://github.com/liatrio/lead-toolchain"
    }
  }

  automount_service_account_token = true
}

// Add roll to allow Jenkins to read secrets
resource "kubernetes_role" "jenkins_kubernetes_credentials" {
  provider  = "kubernetes.toolchain"
  metadata {
    name      = "jenkins-kubernetes-credentials"
    namespace = "${module.toolchain_namespace.name}"

    labels {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations {
      description = "Permission required for Jenkins' Kubernetes Credentials plugin to read secrets"
      source-repo = "https://github.com/liatrio/lead-toolchain"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "watch", "list"]
  }
}

// Bind Kubernetes secrets role to Jenkins service account
resource "kubernetes_role_binding" "jenkins_kubernetes_credentials" {
  provider  = "kubernetes.toolchain"
  metadata {
    name      = "jenkins-kubernetes-credentials"
    namespace = "${module.toolchain_namespace.name}"

    labels {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations {
      description = "Permission required for Jenkins' Kubernetes Credentials plugin to read secrets"
      source-repo = "https://github.com/liatrio/lead-toolchain"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.jenkins_kubernetes_credentials.metadata.0.name}"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.jenkins.metadata.0.name}"
    namespace = "${module.toolchain_namespace.name}"
  }
}