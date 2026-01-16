# Requirements Document

## Introduction

本ドキュメントは、`modules/aws/ecs-fargate/main.tf`の実装要件を定義します。現在、このファイルは空の状態であり、`outputs.tf`で参照されているリソース（ALB、ECS、セキュリティグループなど）が未定義のため、exampleやテストが実行できません。

このspecの目的は、main.tfに完全なECS Fargateインフラを実装することで、以下を実現することです：

1. **Example簡略化**: モジュールを呼び出すだけで完全なBridge環境がデプロイされる
2. **テスト実行可能化**: 実際のリソースがデプロイされ、ヘルスチェックが動作する
3. **セットアップ手順簡略化**: 必要な設定を最小限にし、ユーザーの負担を軽減

## Requirements

### Requirement 1: main.tfファイル構造の整理
**Objective:** モジュール開発者として、main.tfに全リソース定義を集約するか、機能ごとにファイル分割するかを決定したい。これにより、保守性と可読性のバランスが取れた実装を実現できる。

#### Acceptance Criteria

1. WHEN 現在のモジュール構造を確認する THEN 既存の機能別ファイル（`alb.tf`, `ecs.tf`, `iam.tf`, `logs.tf`, `security_groups.tf`）が存在する場合は、main.tfではなくこれらに実装を追加しなければならない
2. WHEN 機能別ファイルが存在しない THEN main.tfに全リソース定義を記述しなければならない
3. WHEN ファイル分割を行う AND 新しい機能別ファイルを作成する THEN ファイル名はスネークケース（例: `alb.tf`, `security_groups.tf`）でなければならない
4. WHEN リソース定義が複数のファイルに分割される THEN 各ファイルは以下のように明確な責任境界を持たなければならない：
   - `alb.tf`: ALB、ターゲットグループ、リスナー、ALBセキュリティグループ
   - `ecs.tf`: ECSクラスター、サービス、タスク定義
   - `security_groups.tf`: Bridgeセキュリティグループ、データベース接続用ルール
   - `iam.tf`: タスク実行ロール、タスクロール、IAMポリシー
   - `logs.tf`: CloudWatch Logsロググループ

### Requirement 2: ECSクラスターとサービスの実装
**Objective:** モジュール開発者として、ECS Fargateでbridgeコンテナを実行するためのクラスターとサービスを実装したい。これにより、outputs.tfで参照されている`aws_ecs_cluster.main`と`aws_ecs_service.bridge`が正しく動作する。

#### Acceptance Criteria

1. WHEN モジュールがapplyされる THEN `aws_ecs_cluster`リソースが作成され、リソース名は`main`でなければならない（outputs.tfとの整合性）
2. WHEN ECSクラスターが作成される THEN クラスター名は`${var.name_prefix}basemachina-bridge`またはデフォルトで`basemachina-bridge`でなければならない
3. WHEN `aws_ecs_service`リソースが作成される THEN リソース名は`bridge`でなければならない（outputs.tfとの整合性）
4. WHEN ECSサービスが作成される THEN 起動タイプは`FARGATE`でなければならない
5. WHEN ECSサービスにタスク数を設定する THEN `desired_count`は`var.desired_count`から取得しなければならない
6. WHEN ECSサービスがネットワーク設定を受け取る THEN サービスは`var.private_subnet_ids`に配置されなければならない
7. WHEN ECSサービスにセキュリティグループを割り当てる THEN Bridgeセキュリティグループ（`aws_security_group.bridge`）が使用されなければならない
8. WHEN ECSサービスがターゲットグループに登録される THEN `load_balancer`ブロックでALBターゲットグループに接続されなければならない
9. IF `var.assign_public_ip`がtrueの場合 THEN Fargateタスクにパブリック IPが割り当てられなければならない

### Requirement 3: ECSタスク定義の実装
**Objective:** モジュール開発者として、bridgeコンテナを実行するためのタスク定義を実装したい。これにより、正しい環境変数とリソース設定でコンテナが起動される。

#### Acceptance Criteria

1. WHEN タスク定義が作成される THEN `network_mode`は`awsvpc`でなければならない（Fargate要件）
2. WHEN タスク定義が作成される THEN `requires_compatibilities`は`["FARGATE"]`でなければならない
3. WHEN タスク定義にCPUとメモリを設定する THEN `cpu`と`memory`は`var.cpu`と`var.memory`から取得しなければならない
4. WHEN タスク定義にIAMロールを割り当てる THEN `execution_role_arn`は`aws_iam_role.task_execution.arn`でなければならない
6. WHEN コンテナ定義が作成される THEN イメージは`public.ecr.aws/basemachina/bridge`でなければならない
7. WHEN コンテナ定義に環境変数を設定する THEN 以下の環境変数が含まれなければならない：
   - `FETCH_INTERVAL`: `var.fetch_interval`
   - `FETCH_TIMEOUT`: `var.fetch_timeout`
   - `PORT`: `tostring(var.port)`（文字列変換）
   - `TENANT_ID`: `var.tenant_id`
8. WHEN コンテナ定義にポートマッピングを設定する THEN `containerPort`は`var.port`（デフォルト8080）でなければならない
9. WHEN コンテナ定義にログ設定を追加する THEN `logConfiguration`は`awslogs`ドライバーを使用し、`aws_cloudwatch_log_group.bridge`を参照しなければならない

### Requirement 4: Application Load Balancer（ALB）の実装
**Objective:** モジュール開発者として、HTTPS終端とルーティングを行うALBを実装したい。これにより、outputs.tfで参照されている`aws_lb.main`が正しく動作する。

#### Acceptance Criteria

1. WHEN `aws_lb`リソースが作成される THEN リソース名は`main`でなければならない（outputs.tfとの整合性）
2. WHEN ALBが作成される THEN `load_balancer_type`は`application`でなければならない
3. WHEN ALBが作成される THEN `internal`はfalseでなければならない（インターネット向け）
4. WHEN ALBがサブネットに配置される THEN `subnets`は`var.public_subnet_ids`でなければならない
5. WHEN ALBにセキュリティグループを割り当てる THEN `security_groups`は`[aws_security_group.alb.id]`でなければならない
6. WHEN `aws_lb_target_group`が作成される THEN `target_type`は`ip`でなければならない（Fargate要件）
7. WHEN ターゲットグループが作成される THEN `port`は`var.port`（デフォルト8080）でなければならない
8. WHEN ターゲットグループが作成される THEN `protocol`は`HTTP`でなければならない
9. WHEN ターゲットグループが作成される THEN `vpc_id`は`var.vpc_id`でなければならない
10. WHEN ターゲットグループにヘルスチェックを設定する THEN `health_check`ブロックで以下を設定しなければならない：
    - `path`: `/ok`
    - `protocol`: `HTTP`
    - `matcher`: `200`
    - `interval`: 30（秒）
    - `timeout`: 5（秒）
11. WHEN `aws_lb_listener`が作成される THEN `port`は443でなければならない
12. WHEN ALBリスナーが作成される THEN `protocol`は`HTTPS`でなければならない
13. WHEN ALBリスナーにSSL証明書を設定する THEN `certificate_arn`は`var.certificate_arn`から取得しなければならない
14. WHEN ALBリスナーのデフォルトアクションを設定する THEN `type`は`forward`で、ターゲットグループに転送しなければならない

### Requirement 5: セキュリティグループの実装
**Objective:** モジュール開発者として、ALBとBridgeのセキュリティグループを実装したい。これにより、outputs.tfで参照されている`aws_security_group.alb`と`aws_security_group.bridge`が正しく動作する。

#### Acceptance Criteria

1. WHEN `aws_security_group`（ALB用）が作成される THEN リソース名は`alb`でなければならない（outputs.tfとの整合性）
2. WHEN ALBセキュリティグループが作成される THEN `vpc_id`は`var.vpc_id`でなければならない
3. WHEN ALBセキュリティグループにインバウンドルールを追加する THEN 以下のルールが含まれなければならない：
   - `from_port`: 443
   - `to_port`: 443
   - `protocol`: `tcp`
   - `cidr_blocks`: `["34.85.43.93/32"]`（BaseMachina IPホワイトリスト）
4. WHEN ALBセキュリティグループにアウトバウンドルールを追加する THEN 全ての送信トラフィック（0.0.0.0/0）が許可されなければならない
5. WHEN `aws_security_group`（Bridge用）が作成される THEN リソース名は`bridge`でなければならない（outputs.tfとの整合性）
6. WHEN Bridgeセキュリティグループが作成される THEN `vpc_id`は`var.vpc_id`でなければならない
7. WHEN Bridgeセキュリティグループにインバウンドルールを追加する THEN ALBセキュリティグループからの通信（ポート`var.port`）が許可されなければならない
8. WHEN Bridgeセキュリティグループにアウトバウンドルールを追加する THEN 全ての送信トラフィック（0.0.0.0/0）が許可されなければならない（BaseMachina API、データソースへのアクセス）
9. WHEN モジュールが`bridge_security_group_id`を出力する THEN モジュールユーザーはこの出力値を使って、接続先リソース（RDS、API等）のセキュリティグループルールを自分で追加できなければならない

### Requirement 6: IAMロールとポリシーの実装
**Objective:** モジュール開発者として、タスク実行ロールとタスクロールを実装したい。これにより、outputs.tfで参照されている`aws_iam_role.task_execution`と`aws_iam_role.task`が正しく動作する。

#### Acceptance Criteria

1. WHEN `aws_iam_role`（タスク実行ロール）が作成される THEN リソース名は`task_execution`でなければならない（outputs.tfとの整合性）
2. WHEN タスク実行ロールが作成される THEN `assume_role_policy`のプリンシパルは`ecs-tasks.amazonaws.com`でなければならない
3. WHEN タスク実行ロールが作成される THEN `aws_iam_role_policy_attachment`で`arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy`がアタッチされなければならない
4. WHEN タスク実行ロールにCloudWatch Logs権限を追加する THEN インラインポリシーまたはカスタムポリシーで`logs:CreateLogStream`と`logs:PutLogEvents`が許可されなければならない
Note: タスクロール（`aws_iam_role.task`）は削除されました。BridgeはAWS SDKを使用しないため、アプリケーション用のIAMロールは不要です。

### Requirement 7: CloudWatch Logsの実装
**Objective:** モジュール開発者として、Bridgeコンテナのログを一元管理するためのロググループを実装したい。これにより、outputs.tfで参照されている`aws_cloudwatch_log_group.bridge`が正しく動作する。

#### Acceptance Criteria

1. WHEN `aws_cloudwatch_log_group`が作成される THEN リソース名は`bridge`でなければならない（outputs.tfとの整合性）
2. WHEN ロググループが作成される THEN `name`は`/ecs/basemachina-bridge`またはname_prefixを考慮した名前でなければならない
3. WHEN ロググループが作成される THEN `retention_in_days`は`var.log_retention_days`から取得しなければならない
4. WHEN `var.log_retention_days`が指定されない THEN デフォルトで7日間保持されなければならない（variables.tfのデフォルト値）

### Requirement 8: 既存のoutputs.tfとの整合性
**Objective:** モジュール開発者として、outputs.tfで参照されている全リソースが正しく定義されていることを確認したい。これにより、モジュールのapply時にエラーが発生しない。

#### Acceptance Criteria

1. WHEN outputs.tfが`aws_lb.main.dns_name`を参照する THEN `aws_lb`リソース（リソース名`main`）が定義されなければならない
2. WHEN outputs.tfが`aws_lb.main.arn`を参照する THEN `aws_lb`リソース（リソース名`main`）が定義されなければならない
3. WHEN outputs.tfが`aws_security_group.alb.id`を参照する THEN `aws_security_group`リソース（リソース名`alb`）が定義されなければならない
4. WHEN outputs.tfが`aws_ecs_cluster.main.name`を参照する THEN `aws_ecs_cluster`リソース（リソース名`main`）が定義されなければならない
5. WHEN outputs.tfが`aws_ecs_cluster.main.arn`を参照する THEN `aws_ecs_cluster`リソース（リソース名`main`）が定義されなければならない
6. WHEN outputs.tfが`aws_ecs_service.bridge.name`を参照する THEN `aws_ecs_service`リソース（リソース名`bridge`）が定義されなければならない
7. WHEN outputs.tfが`aws_security_group.bridge.id`を参照する THEN `aws_security_group`リソース（リソース名`bridge`）が定義されなければならない
8. WHEN outputs.tfが`aws_cloudwatch_log_group.bridge.name`を参照する THEN `aws_cloudwatch_log_group`リソース（リソース名`bridge`）が定義されなければならない
9. WHEN outputs.tfが`aws_iam_role.task_execution.arn`を参照する THEN `aws_iam_role`リソース（リソース名`task_execution`）が定義されなければならない

### Requirement 9: Exampleの簡略化
**Objective:** モジュールユーザーとして、モジュールを呼び出すだけで完全なBridge環境がデプロイされることを確認したい。これにより、セットアップ手順が最小限になる。

#### Acceptance Criteria

1. WHEN `examples/aws-ecs-fargate/main.tf`がモジュールを呼び出す THEN モジュールは必要な全リソース（ALB、ECS、セキュリティグループなど）を自動的に作成しなければならない
2. WHEN ユーザーがExampleをデプロイする THEN 以下の変数のみを設定すればデプロイ可能でなければならない：
   - `vpc_id`
   - `private_subnet_ids`
   - `public_subnet_ids`
   - `tenant_id`
   - `certificate_arn`（オプション）
3. WHEN モジュールがapplyされる THEN `terraform output`で全ての出力値（ALB DNS名、ECSクラスター名など）が取得可能でなければならない
4. WHEN ユーザーがRoute 53レコードを設定する THEN `alb_dns_name`出力値を使用してCNAMEレコードを作成できなければならない
5. WHEN ユーザーがBridgeから接続先リソース（RDS、API等）への接続を設定する THEN `bridge_security_group_id`出力値を使ってセキュリティグループルールを追加できなければならない

### Requirement 10: テストの実行可能化
**Objective:** モジュール開発者として、Terratestによる統合テストが正しく実行されることを確認したい。これにより、CI/CDパイプラインでの自動テストが可能になる。

#### Acceptance Criteria

1. WHEN `test/aws/ecs_fargate_test.go`が実行される THEN モジュールは正しくapplyされなければならない
2. WHEN テストがECSサービスを確認する THEN `desired_count`の数だけタスクが実行中（running）でなければならない
3. WHEN テストがALBターゲットグループを確認する THEN `desired_count`の数だけターゲットが`healthy`状態でなければならない
4. WHEN テストが出力値を確認する THEN `terraform.Output()`で全ての出力値が取得可能でなければならない：
   - `alb_dns_name`
   - `alb_arn`
   - `alb_security_group_id`
   - `ecs_cluster_name`
   - `ecs_cluster_arn`
   - `ecs_service_name`
   - `bridge_security_group_id`
   - `cloudwatch_log_group_name`
   - `task_execution_role_arn`
5. WHEN テストが完了する THEN `terraform destroy`で全リソースがクリーンアップされなければならない

### Requirement 11: variables.tfとの整合性確認
**Objective:** モジュール開発者として、既存のvariables.tfで定義された全変数がリソース定義で正しく使用されることを確認したい。これにより、未使用の変数や参照エラーが発生しない。

#### Acceptance Criteria

1. WHEN リソース定義で変数を参照する THEN variables.tfで定義された変数のみを使用しなければならない
2. WHEN variables.tfに定義された必須変数がある THEN 全ての必須変数（`default`なし）がリソース定義で使用されなければならない
3. WHEN 以下の変数が参照される THEN 対応するリソースで正しく使用されなければならない：
   - `var.vpc_id`: セキュリティグループ、ALB、ターゲットグループ
   - `var.private_subnet_ids`: ECSサービス
   - `var.public_subnet_ids`: ALB
   - `var.certificate_arn`: ALBリスナー
   - `var.tenant_id`: タスク定義の環境変数
   - `var.fetch_interval`: タスク定義の環境変数
   - `var.fetch_timeout`: タスク定義の環境変数
   - `var.port`: タスク定義、ターゲットグループ、セキュリティグループルール
   - `var.cpu`: タスク定義
   - `var.memory`: タスク定義
   - `var.desired_count`: ECSサービス
   - `var.assign_public_ip`: ECSサービスのネットワーク設定
   - `var.log_retention_days`: CloudWatch Logsロググループ
   - `var.tags`: 全リソース
   - `var.name_prefix`: リソース名

### Requirement 12: オプション変数の適切なハンドリング
**Objective:** モジュール開発者として、オプション変数（`default = null`）が指定されない場合でもモジュールが正しく動作することを確認したい。これにより、柔軟な設定が可能になる。

#### Acceptance Criteria

1. WHEN `var.certificate_arn`がnullの場合 THEN テスト用の自己署名証明書が自動生成されるか、または適切なエラーメッセージが表示されなければならない
2. WHEN `var.name_prefix`が空文字列の場合 THEN リソース名は`basemachina-bridge-*`の形式でなければならない
3. WHEN `var.tags`が空のmapの場合 THEN リソースは共通タグなしで作成されなければならない
