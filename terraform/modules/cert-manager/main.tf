# -----------------------------
# Cert-Manager Installation
# -----------------------------
# Cert-manager est requis pour Actions Runner Controller
# Il gère les certificats TLS pour les webhooks

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name                       = "cert-manager"
      "cert-manager.io/disable-validation" = "true"
    }
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = kubernetes_namespace.cert_manager.metadata[0].name
  }

  timeout = 600
  wait    = true

  depends_on = [
    kubernetes_namespace.cert_manager
  ]
}
