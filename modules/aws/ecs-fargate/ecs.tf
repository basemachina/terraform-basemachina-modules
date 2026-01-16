# ========================================
# Data Sources
# ========================================
# 現在のAWSリージョンを取得（CloudWatch Logsで使用）

data "aws_region" "current" {}

# ========================================
# ECS Cluster
# ========================================
# Fargate タスクを実行するための論理的なクラスター
# - Container Insights有効化でメトリクス収集
# - サーバーレス環境（インスタンス管理不要）

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}basemachina-bridge"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}basemachina-bridge"
    }
  )
}

# ========================================
# ECS Task Definition
# ========================================
# Bridgeコンテナの実行仕様を定義
# - Fargateタイプでサーバーレス実行
# - awsvpcネットワークモードでENI割り当て
# - CloudWatch Logsへのログ転送設定

resource "aws_ecs_task_definition" "bridge" {
  family                   = "${var.name_prefix}basemachina-bridge"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "bridge"
      image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/basemachina/bridge:${var.bridge_image_tag}"

      portMappings = [
        {
          containerPort = var.port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "FETCH_INTERVAL"
          value = var.fetch_interval
        },
        {
          name  = "FETCH_TIMEOUT"
          value = var.fetch_timeout
        },
        {
          name  = "PORT"
          value = tostring(var.port)
        },
        {
          name  = "TENANT_ID"
          value = var.tenant_id
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.bridge.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "bridge"
        }
      }
    }
  ])

  tags = var.tags
}

# ========================================
# ECS Service
# ========================================
# Fargateタスクのライフサイクル管理
# - desired_countに基づいてタスク数を維持
# - ALBターゲットグループへの自動登録
# - プライベートサブネット配置でセキュリティ確保

resource "aws_ecs_service" "bridge" {
  name            = "${var.name_prefix}basemachina-bridge"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.bridge.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.bridge.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bridge.arn
    container_name   = "bridge"
    container_port   = var.port
  }

  depends_on = [
    aws_lb_listener.https
  ]

  tags = var.tags
}
