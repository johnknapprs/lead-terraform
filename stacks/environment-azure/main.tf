terraform {
  backend "azurem" {}
}

provider "azurem" {
  version = "~> 1.28.0"
}

provider "azuread" {
  version = "~> 0.3.0"
}

provider "random" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "kubernetes" {
  version                = "~> 1.7"
  host                   = "test"
}

provider "helm" {
  alias = "system"
  namespace = "${module.infrastructure.namespace}"
  tiller_image = "gcr.io/kubernetes-helm/tiller:v2.14.1"
  service_account = "${module.infrastructure.tiller_service_account}"

  kubernetes {
    host                   = "${data.aws_eks_cluster.cluster.endpoint}"
    cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}"
    token                  = "${data.aws_eks_cluster_auth.cluster.token}"
    load_config_file       = false
  }
}

provider "helm" {
  alias = "toolchain"
  namespace = "${module.toolchain.namespace}"
  tiller_image = "gcr.io/kubernetes-helm/tiller:v2.14.1"
  service_account = "${module.toolchain.tiller_service_account}"

  kubernetes {
    host                   = "${data.aws_eks_cluster.cluster.endpoint}"
    cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)}"
    token                  = "${data.aws_eks_cluster_auth.cluster.token}"
    load_config_file       = false
  }
}
