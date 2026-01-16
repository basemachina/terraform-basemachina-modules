# Requirements Document

## Introduction

Google Cloud RunでBaseMachina bridgeをデプロイするための包括的なTerraformソリューションを提供します。既存のAWS ECS Fargate実装と同様の構造で、再利用可能なTerraformモジュール、実践的なデプロイ例、および自動化されたテストを整備することで、GCPユーザーが迅速かつ確実にBridge環境を構築できるようにします。

このプロジェクトにより、マルチクラウド戦略をサポートし、各クラウドプロバイダーのベストプラクティスに従った実装を提供することで、BaseMachinaのエンタープライズ導入を促進します。

## Requirements

### Requirement 1: Google Cloud Run用Terraformモジュール
**Objective:** インフラエンジニアとして、Google Cloud RunでBaseMachina bridgeをデプロイできる再利用可能なTerraformモジュールが欲しい。これにより、標準化された方法でBridge環境を迅速に構築できる。

#### Acceptance Criteria

1. WHEN ユーザーがモジュールを初期化するとき、THEN Cloud Run Moduleは必要な入力変数（project_id、region、bridge_image、tenant_id等）を定義すること
2. WHEN モジュールが適用されるとき、THEN Cloud Run Moduleはマネージド型のCloud Runサービスを作成すること
3. WHEN Cloud Runサービスが作成されるとき、THEN Cloud Run Moduleは指定されたBridgeコンテナイメージ（ghcr.io/basemachina/bridge）を使用すること
4. WHEN モジュールが実行されるとき、THEN Cloud Run ModuleはBridgeの環境変数（FETCH_INTERVAL、FETCH_TIMEOUT、PORT、TENANT_ID）を設定すること
5. WHEN HTTPS通信が有効化されているとき、THEN Cloud Run ModuleはCloud Load BalancingとGoogle-managed SSL証明書を構成すること
6. WHEN カスタムドメインが指定されているとき、THEN Cloud Run ModuleはCloud DNSレコードを作成すること
7. WHEN モジュールが完了するとき、THEN Cloud Run Moduleは重要な出力値（service_url、service_name、load_balancer_ip等）を提供すること
8. WHEN モジュールがデプロイされるとき、THEN Cloud Run ModuleはBaseMachinaのIPアドレス（34.85.43.93）からのアクセスを許可するIngress設定を行うこと

### Requirement 2: 実践的なデプロイ例（Example）
**Objective:** DevOpsエンジニアとして、実際のデプロイシナリオを示す包括的なexampleが欲しい。これにより、モジュールの使い方を理解し、自社環境に適用できる。

#### Acceptance Criteria

1. WHEN ユーザーがexampleを参照するとき、THEN GCP Cloud Run Exampleはモジュールの基本的な使用方法を示すmain.tfを含むこと
2. WHEN exampleが実行されるとき、THEN GCP Cloud Run ExampleはCloud SQLインスタンス（PostgreSQL）を作成してBridgeの接続先として使用すること
3. WHEN exampleが構成されるとき、THEN GCP Cloud Run Exampleはカスタマイズ可能な変数をvariables.tfで定義すること
4. WHEN ユーザーが設定を始めるとき、THEN GCP Cloud Run Exampleは設定例としてterraform.tfvars.exampleを提供すること
5. WHEN exampleがデプロイされるとき、THEN GCP Cloud Run Exampleは重要な情報（BridgeのURL、Cloud SQL接続名等）を出力すること
6. WHEN カスタムドメインを使用するとき、THEN GCP Cloud Run ExampleはCloud DNS統合とSSL証明書の自動管理を含むこと
7. WHEN データベース初期化が必要なとき、THEN GCP Cloud Run Exampleはサンプルデータを投入するためのSQLスクリプトを提供すること
8. WHEN ユーザーがexampleをデプロイするとき、THEN GCP Cloud Run Exampleは詳細なREADME.mdでステップバイステップの手順を提供すること

### Requirement 3: 自動化されたテスト
**Objective:** 品質保証エンジニアとして、モジュールとexampleが正しく動作することを検証する自動テストが欲しい。これにより、コード変更時の回帰を防ぎ、信頼性を確保できる。

#### Acceptance Criteria

1. WHEN テストが実行されるとき、THEN Cloud Run Test SuiteはTerratestフレームワーク（Go言語）を使用すること
2. WHEN テストが開始されるとき、THEN Cloud Run Test Suiteは実際のGCP環境にリソースをデプロイすること
3. WHEN Cloud Runサービスがデプロイされるとき、THEN Cloud Run Test SuiteはBridgeの `/ok` エンドポイントへのHTTPSアクセスが成功することを検証すること
4. WHEN テストが実行されるとき、THEN Cloud Run Test SuiteはCloud SQLへの接続が確立できることを検証すること
5. WHEN カスタムドメインが設定されているとき、THEN Cloud Run Test SuiteはDNSレコードとSSL証明書が正しく構成されていることを検証すること
6. WHEN テストが完了するとき、THEN Cloud Run Test Suiteはデプロイしたすべてのリソースをクリーンアップすること
7. WHEN テストが失敗するとき、THEN Cloud Run Test Suiteは詳細なエラーメッセージとログを提供すること
8. WHEN 環境変数が設定されているとき、THEN Cloud Run Test SuiteはGCPプロジェクトIDとリージョンなどのテスト設定を環境変数から取得すること

### Requirement 4: プロジェクト構造とドキュメント
**Objective:** 開発者として、既存のAWS実装と一貫性のあるプロジェクト構造とドキュメントが欲しい。これにより、マルチクラウド環境でのメンテナンスが容易になる。

#### Acceptance Criteria

1. WHEN モジュールが配置されるとき、THEN Project Structureは `modules/gcp/cloud-run/` ディレクトリ配下に整理されること
2. WHEN exampleが配置されるとき、THEN Project Structureは `examples/gcp-cloud-run/` ディレクトリ配下に整理されること
3. WHEN テストが配置されるとき、THEN Project Structureは `test/gcp/` ディレクトリ配下に整理されること
4. WHEN モジュールファイルが作成されるとき、THEN Project Structureは標準的なTerraform構成（main.tf、variables.tf、outputs.tf、versions.tf、README.md）に従うこと
5. WHEN ドキュメントが生成されるとき、THEN Module Documentationはterraform-docsを使用して自動生成されること
6. WHEN ユーザーがREADMEを参照するとき、THEN Module Documentationは入力変数、出力値、使用例、前提条件を含むこと
7. WHEN プロジェクトが更新されるとき、THEN Project Structureは `.kiro/steering/structure.md` に新しいGCPディレクトリ構造を反映すること
8. WHEN exampleのREADMEが作成されるとき、THEN Example Documentationは前提条件、セットアップ手順、テスト方法、トラブルシューティングを含むこと

### Requirement 5: セキュリティとネットワーク構成
**Objective:** セキュリティエンジニアとして、Cloud Run環境が適切なセキュリティ設定とネットワーク構成を持つことを保証したい。これにより、本番環境での安全な運用が可能になる。

#### Acceptance Criteria

1. WHEN Bridgeサービスが公開されるとき、THEN Security ConfigurationはBaseMachinaのIPアドレス（34.85.43.93）からのアクセスのみを許可すること
2. WHEN HTTPS通信が有効化されているとき、THEN Security ConfigurationはHTTP通信をHTTPSにリダイレクトすること
3. WHEN Cloud SQLに接続するとき、THEN Network ConfigurationはServerless VPC Accessコネクタを使用してプライベートIP接続を確立すること
4. WHEN サービスアカウントが作成されるとき、THEN IAM Configurationは最小権限の原則に従った権限のみを付与すること
5. WHEN インターネットアクセスが必要なとき、THEN Network ConfigurationはBridgeから外部インターネット（BaseMachina API）へのアクセスを許可すること
7. WHEN Cloud Runサービスが実行されるとき、THEN Security Configurationは認証されていないInvokeリクエストを拒否すること（Ingress設定による制御）
8. WHEN ログが出力されるとき、THEN Logging ConfigurationはCloud Loggingに自動的にコンテナログを送信すること

### Requirement 6: Terraformベストプラクティスとの整合性
**Objective:** Terraformメンテナーとして、GCPモジュールがTerraformおよびGCPのベストプラクティスに準拠していることを確認したい。これにより、長期的なメンテナンス性とクラウド移行の容易性が確保される。

#### Acceptance Criteria

1. WHEN プロバイダーが定義されるとき、THEN Terraform Configurationはバージョン制約（terraform >= 1.0、google ~> 5.0）を指定すること
2. WHEN 変数が定義されるとき、THEN Variable Definitionsは型、説明、デフォルト値、バリデーションルールを含むこと
3. WHEN リソースが作成されるとき、THEN Resource Namingは一貫した命名規則（スネークケース）に従うこと
4. WHEN モジュールがフォーマットされるとき、THEN Code Formattingは `terraform fmt` による標準フォーマットを使用すること
5. WHEN コードが検証されるとき、THEN Code Validationは `terraform validate` で構文エラーがないこと
6. WHEN セキュリティスキャンが実行されるとき、THEN Security Scanningは `tfsec` でセキュリティ問題がないこと
7. WHEN リソースにタグが付けられるとき、THEN Resource Taggingは環境、プロジェクト、管理者などの標準的なラベルを含むこと
8. WHEN 出力値が定義されるとき、THEN Output Definitionsは明確な説明と適切な型を含むこと
