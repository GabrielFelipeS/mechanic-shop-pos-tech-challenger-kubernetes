terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

# As credenciais vem do bloco "AWS CLI" do AWS Academy (aws_access_key_id,
# aws_secret_access_key e aws_session_token em ~/.aws/credentials). Nao ha
# assume_role aqui: o lab ja entrega uma sessao assumida de voclabs.
provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# ---------------------------------------------------------------------------
# Autenticacao no cluster
#
# O token de data.aws_eks_cluster_auth vale 15 minutos e e gerado UMA VEZ, no
# inicio do apply. Um apply do zero (cluster ~10min + node group ~3min + addon
# EBS ~3min) estoura esse prazo antes de chegar nos manifests, e o resultado e:
#
#   Error: ... failed to run apply: ... from server for: "...": Unauthorized
#
# Com exec o token passa a ser gerado sob demanda, a cada chamada, e o problema
# desaparece. Isso exige o aws CLI instalado (que o kubectl tambem precisa).
# Quem nao puder instalar pode usar use_exec_auth = false e torcer para o apply
# caber em 15 minutos — na pratica, so funciona em applies incrementais.
# ---------------------------------------------------------------------------

locals {
  exec_auth = var.use_exec_auth ? [1] : []

  static_token = var.use_exec_auth ? null : data.aws_eks_cluster_auth.auth.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = local.static_token

    dynamic "exec" {
      for_each = local.exec_auth

      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name, "--region", var.region]
      }
    }
  }
}
