# ========================================
# Service Account
# ========================================
# Bridge用のサービスアカウントを作成
# 最小権限の原則に従い、必要な権限のみを付与

resource "google_service_account" "bridge" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for BaseMachina Bridge"
  project      = var.project_id
}

# ========================================
# IAM Role Bindings
# ========================================

# Cloud SQL Client権限
# Cloud SQLインスタンスへの接続に必要
resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.bridge.email}"
}

# Cloud Logging書き込み権限
# コンテナログをCloud Loggingに送信するために必要
resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bridge.email}"
}

# ========================================
# Cloud Run Service
# ========================================

resource "google_cloud_run_v2_service" "bridge" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  # Load Balancerからのトラフィックのみを許可
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    # サービスアカウントの関連付け
    service_account = google_service_account.bridge.email

    # コンテナ設定
    containers {
      # Bridgeコンテナイメージ（gcr.io固定）
      image = "gcr.io/basemachina/bridge:${var.bridge_image_tag}"

      # Bridge環境変数
      env {
        name  = "FETCH_INTERVAL"
        value = var.fetch_interval
      }
      env {
        name  = "FETCH_TIMEOUT"
        value = var.fetch_timeout
      }
      env {
        name  = "TENANT_ID"
        value = var.tenant_id
      }
      # 注意: PORT環境変数はCloud Runが自動的に設定するため、ここでは設定しません
      # container_portで指定したポート番号がPORT環境変数として自動的に設定されます

      # リソース制限
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # コンテナポート
      ports {
        container_port = var.port
      }
    }

    # スケーリング設定
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # VPCネットワーク統合
    # Direct VPC EgressまたはVPC Connectorを使用
    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null || var.vpc_network_id != null ? [1] : []
      content {
        # VPC Connectorを使用する場合
        connector = var.vpc_connector_id

        # Direct VPC Egressを使用する場合
        dynamic "network_interfaces" {
          for_each = var.vpc_network_id != null ? [1] : []
          content {
            network    = var.vpc_network_id
            subnetwork = var.vpc_subnetwork_id
          }
        }

        # VPC Egress設定
        egress = var.vpc_egress
      }
    }
  }

  # ラベル
  labels = var.labels
}

# ========================================
# Cloud Run IAM Policy
# ========================================
# Load BalancerからCloud Runへのアクセスを許可
# Cloud Armorでアクセス制御を行うため、allUsersにInvoker権限を付与

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  name     = google_cloud_run_v2_service.bridge.name
  location = google_cloud_run_v2_service.bridge.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "allUsers"
}
