module "staging_namespace" {
  source     = "../../common/namespace"
  namespace  = "${var.product_name}-staging"
  labels {
    "istio-injection" = "enabled"
    "appmesh.k8s.aws/sidecarInjectorWebhook" = "enabled"
  }
  annotations {
    name  = "${var.product_name}-staging"
    "opa.lead.liatrio/ingress-whitelist" = "*.${var.product_name}-staging.${var.cluster_domain}"
    "opa.lead.liatrio/image-whitelist" = "${var.image_whitelist}"
  }
  providers {
    helm = "helm.staging"
    kubernetes = "kubernetes.staging"
  }
}

module "staging_ingress" {
  source = "../../common/nginx-ingress"
  namespace  = "${module.staging_namespace.name}"
  ingress_controller_type = "${var.ingress_controller_type}"

  providers {
    helm = "helm.staging"
    kubernetes = "kubernetes.staging"
  }
}

module "staging_issuer" {
  source = "../../common/cert-issuer"
  namespace  = "${module.staging_namespace.name}"
  issuer_type = "${var.issuer_type}"
  crd_waiter  = ""

  providers {
    helm = "helm.staging"
  }
}

resource "kubernetes_role" "jenkins_staging_role" {
  provider  = "kubernetes.staging"
  metadata {
    name      = "jenkins-staging-role"
    namespace  = "${module.staging_namespace.name}"

    labels {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations {
      description = "Permission required for Jenkins' to get pods in staging namespace"
      source-repo = "https://github.com/liatrio/lead-terraform"
    }
  }

  rule {
    api_groups = ["","extensions"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "jenkins_staging_rolebinding" {
  provider  = "kubernetes.staging"
  metadata {
    name      = "jenkins-staging-rolebinding"
    namespace  = "${module.staging_namespace.name}"

    labels {
      "app.kubernetes.io/name"       = "jenkins"
      "app.kubernetes.io/instance"   = "jenkins"
      "app.kubernetes.io/component"  = "jenkins-master"
      "app.kubernetes.io/managed-by" = "Terraform"
    }

    annotations {
      description = "Permission required for Jenkins' to get pods in staging namespace"
      source-repo = "https://github.com/liatrio/lead-terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.jenkins_staging_role.metadata.0.name}"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.jenkins.metadata.0.name}"
    namespace = "${module.toolchain_namespace.name}"
  }
}

data "helm_repository" "flagger" {
    name = "flagger"
    url  = "https://flagger.app"
}
resource "helm_release" "podinfo" {
  provider   = "kubernetes.staging"
  repository = "${data.helm_repository.flagger.metadata.0.name}"
  chart      = "podinfo"
  namespace  = "${module.staging_namespace.name}"
  name       = "podinfo"
  timeout    = 600
  wait       = true

  set {
    name = "backend"
    value = "http://backend.test:9898/echo"
  }

  set {
    name = "canary.enabled"
    value = "true"
  }

  set {
    name = "canary.istioIngress.enabled"
    value = "true"
  }

  set {
    name = "canary.istioIngress.gateway"
    value = "istio-ingressgateway"
  }

  set {
    name = "canary.istioIngress.host"
    value = "podinfo.jon-test-staging.lead.sandbox.liatr.io"
  }
}
