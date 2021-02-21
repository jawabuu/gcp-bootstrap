provider "kubernetes" {
  config_path = var.kubeconfig
}

# NGINX INGRESS NAMESPACE
resource "kubernetes_namespace" "ingress_nginx_namespace" {
  metadata {
    name = "ingress-nginx"
  }
}

# CERT MANAGER NAMESPACE
resource "kubernetes_namespace" "certmanager_namespace" {
  metadata {
    name = "cert-manager"
  }
}

# ARGO CD NAMESPACE
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}