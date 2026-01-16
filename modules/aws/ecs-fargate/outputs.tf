# ========================================
# ALB Outputs
# ========================================
# Application Load BalancerのDNS名とARN
# Route 53レコード作成や他のリソース参照に使用

output "alb_dns_name" {
  description = "ALBのDNS名（Route 53レコード作成用）"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALBのARN（リソース参照用）"
  value       = aws_lb.main.arn
}

output "alb_security_group_id" {
  description = "ALBセキュリティグループのID（通信ルール設定用）"
  value       = aws_security_group.alb.id
}

# ========================================
# ECS Outputs
# ========================================
# ECSクラスターとサービスの情報
# モニタリングやスケーリング設定に使用

output "ecs_cluster_name" {
  description = "ECSクラスター名（AWS CLIやモニタリング用）"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECSクラスターARN（リソース参照用）"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_name" {
  description = "ECSサービス名（デプロイやスケーリング用）"
  value       = aws_ecs_service.bridge.name
}

# ========================================
# Security Group Outputs
# ========================================
# Bridgeセキュリティグループの情報
# データベースやAPIへのアクセス許可設定に使用

output "bridge_security_group_id" {
  description = "BridgeセキュリティグループのID（他リソースとの通信ルール設定用）"
  value       = aws_security_group.bridge.id
}

# ========================================
# CloudWatch Logs Outputs
# ========================================
# ロググループ情報
# ログストリーム確認やメトリクスフィルター設定に使用

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logsロググループ名（ログ確認用）"
  value       = aws_cloudwatch_log_group.bridge.name
}

# ========================================
# IAM Role Outputs
# ========================================
# タスク実行ロールのARN
# 権限の追加や参照に使用

output "task_execution_role_arn" {
  description = "タスク実行ロールARN（権限管理用）"
  value       = aws_iam_role.task_execution.arn
}

# ========================================
# VPC Endpoints Outputs
# ========================================
# VPCエンドポイントの情報
# ネットワーク診断やトラブルシューティングに使用

output "vpc_endpoint_ecr_api_id" {
  description = "ECR API VPCエンドポイントID"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ECR Docker VPCエンドポイントID"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "vpc_endpoint_s3_id" {
  description = "S3 VPCエンドポイントID"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_logs_id" {
  description = "CloudWatch Logs VPCエンドポイントID"
  value       = aws_vpc_endpoint.logs.id
}

output "vpc_endpoints_security_group_id" {
  description = "VPCエンドポイント用セキュリティグループID"
  value       = aws_security_group.vpc_endpoints.id
}

# ========================================
# ECR Pull Through Cache Outputs
# ========================================

output "bridge_image_uri" {
  description = "使用されているBridgeコンテナイメージURI"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecr-public/basemachina/bridge:${var.bridge_image_tag}"
}

# ========================================
# NAT Gateway Outputs
# ========================================

output "nat_gateway_id" {
  description = "NAT Gateway ID (created or existing)"
  value       = local.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP address (null if using existing NAT Gateway)"
  value       = local.create_nat_gateway ? aws_eip.nat[0].public_ip : null
}

# ========================================
# Route53 / DNS Outputs
# ========================================

output "route53_record_fqdn" {
  description = "Route53レコードのFQDN"
  value       = aws_route53_record.bridge.fqdn
}

output "domain_name" {
  description = "設定されたカスタムドメイン名"
  value       = var.domain_name
}

output "route53_zone_id" {
  description = "使用されたRoute53 Hosted Zone ID"
  value       = var.route53_zone_id
}
