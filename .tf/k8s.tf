locals {
  namespace = "auto-assign-bot"
}

resource "kubernetes_config_map" "api" {
  metadata {
    name = "api"
    namespace = local.namespace
  }

  data = {
    ENV                 = var.env
    # DD_ENV              = var.env
    APP_ID              = var.APP_ID
    WEBHOOK_SECRET      = var.WEBHOOK_SECRET
    LOG_LEVEL           = var.LOG_LEVEL
    WEBHOOK_PROXY_URL   = var.WEBHOOK_PROXY_URL
    PRIVATE_KEY_PATH    = var.PRIVATE_KEY_PATH
  }
}

resource "kubernetes_config_map" "private-key" {
  metadata {
    name = "private-key"
    namespace = local.namespace
  }

  data = {
    "id_rsa": file("id_rsa"),
  }
}

resource "kubernetes_deployment" "api" {
  metadata {
    name = "api"
    namespace = local.namespace
    labels = {
      app = "api"
      type = "http"
      "tags.datadoghq.com/app.version": "6.0.2"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app = "api"
        }

        annotations = {
          "ad.datadoghq.com/nginx.tags": jsonencode({
            "integration": "nginx"
          })
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project_id}/auto-assign-bot/master:latest"
          name = "app"

          env {
            name = "MODE"
            value = "web"
          }
          env {
            name = "DD_VERSION"
            value_from {
              field_ref {
                field_path = "metadata.labels['tags.datadoghq.com/app.version']"
              }
            }
          }

          volume_mount {
            mount_path = "/app/id_rsa"
            name = "private-key"
            sub_path = "id_rsa"
            read_only = false
          }

          env {
            name = "DD_SERVICE"
            value = var.project
          }

          env_from {
            config_map_ref {
              name = "api"
            }
          }

          port {
            container_port = 3000
          }

          liveness_probe {
            http_get {
              path = "/health/"
              port = 3000
            }

            timeout_seconds = 3
            initial_delay_seconds = 15
            period_seconds = 30
          }

          readiness_probe {
            http_get {
              path = "/health/"
              port = 3000
            }

            timeout_seconds = 3
            initial_delay_seconds = 10
            period_seconds = 10
          }
        }

        volume {
          name = "private-key"
          config_map {
            items {
              key = "id_rsa"
              path = "id_rsa"
            }
            name = "private-key"
          }
        }
      }
    }
  }
  wait_for_rollout = false

  depends_on = [
    kubernetes_config_map.api,
  ]

  lifecycle {
    ignore_changes = [
      spec.0.template.0.spec.0.container.0.image,
      metadata.0.labels["tags.datadoghq.com/app.version"],
    ]
  }
}
resource "kubernetes_service" "api" {
  metadata {
    name = "api"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "api"
    }
    type = "NodePort"
    session_affinity = "ClientIP"
    port {
      port = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_manifest" "managed_certificate" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "networking.gke.io/v1beta2"
    kind = "ManagedCertificate"
    metadata = {
      "name" = "auto-assign"
      "namespace" = local.namespace
    }
    "spec" = {
      "domains" = [
        "auto-assign-bot.diag.vn",
      ]
    }
  }
}

resource "google_compute_global_address" "auto-assign" {
  name = "${var.project}-${var.env}"
}

resource "kubernetes_ingress" "auto-assign" {
  metadata {
    name = "auto-assign"
    namespace = local.namespace
    annotations = {
      "ingress.kubernetes.io/enable-cors" = "true"
      "ingress.kubernetes.io/force-ssl-redirect" = true
      "ingress.kubernetes.io/static-ip" = "${var.project}-${var.env}"
      "networking.gke.io/managed-certificates" = "auto-assign"
    }
  }

  spec {
    backend {
      service_name = "api"
      service_port = "80"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata.0.annotations["ingress.kubernetes.io/static-ip"]
    ]
  }

  depends_on = [
    google_compute_global_address.auto-assign,
    kubernetes_manifest.managed_certificate,
  ]
}
