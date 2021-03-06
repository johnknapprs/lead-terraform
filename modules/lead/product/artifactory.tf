data "kubernetes_secret" "jenkins_artifactory_credential" {
  provider = kubernetes.toolchain
  metadata {
    name      = "jenkins-artifactory-credential"
    namespace = "toolchain"
  }
}

data "template_file" "dockercfg" {
  template = file("${path.module}/artifactory-dockercfg.tpl")

  vars = {
    url   = "https://artifactory.toolchain.${var.cluster_domain}/docker-registry/${var.product_name}"
    email = "jenkins@liatr.io"
    auth = base64encode(
      "${data.kubernetes_secret.jenkins_artifactory_credential.data.username}:${data.kubernetes_secret.jenkins_artifactory_credential.data.password}",
    )
  }
}

resource "kubernetes_secret" "jenkins_artifactory_dockercfg" {
  metadata {
    name      = "jenkins-artifactory-dockercfg"
    namespace = module.toolchain_namespace.name
  }

  data = {
    "config.json" = data.template_file.dockercfg.rendered
  }

  type = "Opaque"
}

