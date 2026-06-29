# 1. Isolated Namespaces Configuration
resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "kubernetes_namespace" "cicd" {
  metadata { name = "cicd" }
}

resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

# 2. Deploy ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.52.0"

  # Disable SSL verification for simple local UI access
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}

# 3. Deploy Jenkins
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.cicd.metadata[0].name

  # Allocate lightweight execution resources for your local VM limits
  set {
    name  = "controller.javaOpts"
    value = "-Xms1024m -Xmx2048m"
  }

  # Root permissions to bypass local file system permission bugs
  set {
    name  = "controller.runAsUser"
    value = "0"
  }

  set {
    name  = "controller.fsGroup"
    value = "0"
  }
}

# 4. Deploy Prometheus & Grafana (Kube-Prometheus-Stack)
resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "56.0.0"

  # Speed up scraping cycles for near real-time updates in testing
  set {
    name  = "prometheus.prometheusSpec.scrapeInterval"
    value = "10s"
  }
}
