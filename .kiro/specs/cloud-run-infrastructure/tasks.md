# Implementation Plan

## Cloud Run Infrastructure実装タスク

このドキュメントは、Google Cloud RunでBaseMachina bridgeをデプロイするためのTerraformモジュール、example、テストの実装タスクを定義します。

---

- [x] 1. Cloud Runモジュールの基盤構築
- [x] 1.1 モジュールディレクトリ構造とTerraform設定の初期化
  - `modules/gcp/cloud-run/`ディレクトリを作成
  - Terraformプロバイダーバージョン制約を定義（terraform >= 1.0、google ~> 5.0）
  - プロバイダー設定とバージョン管理を設定
  - 空のmain.tfを作成（機能別ファイル分割パターンのため）
  - _Requirements: 4.1, 4.4, 6.1_

- [x] 1.2 入力変数の定義とバリデーション
  - プロジェクトとリージョン設定用の変数を定義（project_id、region、service_name）
  - Bridge環境変数用の変数を定義（tenant_id、fetch_interval、fetch_timeout、port）
  - リソース設定用の変数を定義（cpu、memory、min_instances、max_instances）
  - VPCネットワーク設定用の変数を定義（vpc_connector_id、vpc_egress、vpc_network_id、vpc_subnetwork_id）
  - ラベル管理用の変数を定義
  - 各変数に型、説明、デフォルト値、バリデーションルールを追加
  - portが4321でないことを検証するバリデーションを実装
  - vpc_egressが"all-traffic"または"private-ranges-only"であることを検証
  - _Requirements: 1.1, 1.4, 6.2_

- [x] 1.3 出力値の定義
  - Cloud Runサービス情報の出力を定義（service_url、service_name、service_id）
  - サービスアカウント情報の出力を定義（service_account_email）
  - Bridgeイメージ情報の出力を定義（bridge_image_uri）
  - 各出力値に明確な説明を追加
  - _Requirements: 1.7, 6.8_

- [x] 2. Cloud Runサービスの実装
- [x] 2.1 サービスアカウントとIAM権限の設定
  - Bridge用のサービスアカウントを作成
  - Cloud SQL Client権限を付与（cloudsql.client）
  - Cloud Logging書き込み権限を付与（logging.logWriter）
  - 最小権限の原則に従った権限設定を実装
  - Note: Secret Manager権限は削除されました（BridgeはSecret Managerを使用しないため）
  - _Requirements: 5.4, 6.2_

- [x] 2.2 Cloud Runサービスの作成と環境変数設定
  - Cloud Run v2サービスリソースを作成
  - Bridgeコンテナイメージを指定（ghcr.io/basemachina/bridge:latest）
  - Bridge環境変数を設定（FETCH_INTERVAL、FETCH_TIMEOUT、PORT、TENANT_ID）
  - コンテナポート設定を実装
  - リソース制限を設定（CPU、メモリ）
  - スケーリング設定を実装（min_instances、max_instances）
  - ラベルを適用
  - _Requirements: 1.2, 1.3, 1.4, 6.7_

- [x] 2.3 VPCネットワーク統合の実装
  - Ingress設定を"INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"に設定
  - Direct VPC Egress設定を実装（vpc_access.network_interfaces）
  - VPC Connector統合をオプションとして実装（vpc_connector_id使用時）
  - vpc_egress設定を適用（all-traffic or private-ranges-only）
  - サービスアカウントをCloud Runサービスに関連付け
  - _Requirements: 1.8, 5.3, 5.6, 5.7_

- [x] 3. Load BalancerとSSL証明書の実装
- [x] 3.1 Serverless NEGとBackend Serviceの作成
  - グローバル外部IPアドレスを予約
  - Serverless Network Endpoint Group（NEG）を作成
  - Cloud RunサービスをNEGバックエンドとして構成
  - Backend Serviceを作成（プロトコル、タイムアウト設定）
  - Backend ServiceにServerless NEGを関連付け
  - _Requirements: 1.5_

- [x] 3.2 SSL証明書とHTTPS設定の実装
  - Google-managed SSL証明書リソースを作成
  - カスタムドメインを証明書に関連付け
  - URL Mapを作成してBackend Serviceにルーティング
  - HTTPS Target Proxyを作成してSSL証明書を適用
  - Global Forwarding Ruleを作成（ポート443、HTTPS）
  - _Requirements: 1.5, 5.2_

- [x] 3.3 HTTP to HTTPSリダイレクトの実装
  - HTTPリダイレクト用のURL Mapを作成（オプション、enable_https_redirect）
  - リダイレクト設定を実装（https_redirect、MOVED_PERMANENTLY_DEFAULT）
  - HTTP Target Proxyを作成
  - HTTP用のGlobal Forwarding Ruleを作成（ポート80）
  - _Requirements: 5.2_

- [x] 4. Cloud ArmorセキュリティポリシーとDNSの実装
- [x] 4.1 Cloud Armorセキュリティポリシーの作成
  - Cloud Armorセキュリティポリシーリソースを作成
  - BaseMachinaのIPアドレス（34.85.43.93/32）を許可するルールを追加（priority 1000）
  - 追加のIPアドレス範囲を許可するルールを実装（allowed_ip_ranges変数）
  - デフォルトで全アクセスを拒否するルール（403）を追加（priority 2147483647）
  - セキュリティポリシーをBackend Serviceに適用
  - _Requirements: 1.8, 5.1_

- [x] 4.2 Cloud DNS統合の実装
  - Cloud DNS Aレコードリソースを作成
  - カスタムドメイン名をLoad BalancerのIPアドレスにマッピング
  - DNS Managed Zoneとの統合を実装
  - 依存関係を設定（Load Balancer作成後にDNSレコード作成）
  - _Requirements: 1.6, 5.2_

- [x] 5. モジュールの検証と品質保証
- [x] 5.1 Terraformコード品質チェック
  - terraform fmtを実行してフォーマットを統一
  - terraform validateで構文エラーがないことを確認
  - tfsecを実行してセキュリティ問題がないことを検証
  - 命名規則がスネークケースに従っていることを確認
  - _Requirements: 6.3, 6.4, 6.5, 6.6_

- [x] 5.2 モジュールREADMEとドキュメントの作成
  - terraform-docsを使用してREADME.mdを自動生成
  - モジュールの概要と目的を記述
  - 使用例を追加
  - 前提条件を記載（GCP Project、Cloud Run API有効化、VPC設定）
  - 入力変数の説明を確認
  - 出力値の説明を確認
  - _Requirements: 4.4, 4.6, 6.5_

- [x] 6. Cloud Run Exampleの実装
- [x] 6.1 Exampleディレクトリ構造とプロバイダー設定
  - `examples/gcp-cloud-run/`ディレクトリを作成
  - Terraformプロバイダー設定を追加（google、null、random）
  - プロバイダーバージョン制約を定義
  - _Requirements: 4.2, 4.4_

- [x] 6.2 VPCネットワークとサブネットの作成
  - VPCネットワークリソースを作成
  - プライベートサブネットを作成
  - プライベートサービス接続を設定（Cloud SQL用）
  - VPCピアリング接続を確立
  - _Requirements: 5.3_

- [x] 6.3 Cloud SQLインスタンスとデータベースの作成
  - Cloud SQL PostgreSQLインスタンスを作成
  - プライベートIP設定を実装（ipv4_enabled: false）
  - VPCネットワークとの統合を設定
  - データベースを作成
  - データベースユーザーを作成
  - バックアップ設定を実装（point_in_time_recovery）
  - _Requirements: 2.2, 5.3_

- [x] 6.4 Cloud DNSとSSL証明書の設定
  - Cloud DNS Managed Zoneの参照を実装（既存のゾーン使用）
  - カスタムドメイン名を設定
  - SSL証明書の自動発行設定を実装
  - _Requirements: 2.6_

- [x] 6.5 Bridgeモジュールの呼び出しと統合
  - Cloud Runモジュールを呼び出し
  - 必要な変数を渡す（project_id、region、service_name、tenant_id等）
  - VPCネットワーク設定を渡す
  - Load Balancer設定を渡す（domain_name、enable_https_redirect、enable_cloud_armor）
  - 依存関係を設定（VPC、Cloud SQL作成後にモジュール実行）
  - _Requirements: 2.1, 2.3_

- [x] 6.6 Example変数と出力の定義
  - カスタマイズ可能な変数を定義（project_id、region、tenant_id、domain_name等）
  - terraform.tfvars.exampleファイルを作成
  - サンプル設定値を記載
  - 重要な情報を出力（BridgeのURL、Load Balancer IP、Cloud SQL接続名等）
  - _Requirements: 2.3, 2.4, 2.5_

- [x] 6.7 データベース初期化スクリプトの作成
  - scripts/ディレクトリを作成
  - init.sqlスクリプトを作成
  - サンプルテーブルとデータを定義
  - スクリプト実行手順をREADMEに記載
  - _Requirements: 2.7_

- [x] 6.8 Example READMEとドキュメントの作成
  - README.mdを作成
  - 前提条件を記載（GCPプロジェクト、DNS Managed Zone、認証情報）
  - セットアップ手順をステップバイステップで説明
  - terraform.tfvars.exampleのコピーと設定方法を説明
  - デプロイ手順を記載（terraform init、plan、apply）
  - テスト方法を説明（HTTPS疎通確認、ヘルスチェック、Cloud SQL接続）
  - クリーンアップ手順を記載（terraform destroy）
  - トラブルシューティングセクションを追加
  - _Requirements: 2.8, 4.8_

- [x] 7. Terratestによる自動化テストの実装
- [x] 7.1 テストディレクトリ構造とGo環境の設定
  - `test/gcp/`ディレクトリを作成
  - go.modファイルを更新（GCP用の依存関係を追加）
  - Terratestライブラリをインポート
  - Google Cloud Go SDKをインポート
  - _Requirements: 3.1, 4.3_

- [x] 7.2 テストヘルパー関数の実装
  - 環境変数取得ヘルパーを実装（mustGetenv、getenvSlice）
  - GCPクライアント初期化関数を実装
  - リソース存在確認関数を実装
  - リトライロジックを実装（API呼び出し、DNS伝播待機）
  - _Requirements: 3.7, 3.8_

- [x] 7.3 Cloud Run統合テストの実装
  - TestCloudRunModule関数を作成
  - テスト用の一意なリソース名を生成
  - Terraform設定を構築（terraformOptions）
  - terraform.InitAndApplyを実行
  - Cloud Runサービスの存在を検証
  - Cloud Runサービスの設定を検証（環境変数、リソース、ingress設定）
  - terraform.Destroyをdeferで登録（クリーンアップ保証）
  - _Requirements: 3.2, 3.6_

- [x] 7.4 HTTPS疎通とヘルスチェックテストの実装
  - service_url出力値を取得
  - `/ok`エンドポイントへのHTTPSリクエストを実行
  - HTTPステータスコード200を検証
  - レスポンスボディに"ok"が含まれることを検証
  - SSL証明書の有効性を検証
  - リトライロジックを実装（SSL証明書発行待機）
  - _Requirements: 3.3, 3.5_

- [x] 7.5 Cloud SQL接続テストの実装
  - Cloud SQLインスタンス名と接続名を出力値から取得
  - Cloud SQL APIを使用してインスタンスの存在を検証
  - プライベートIP設定を検証
  - Cloud Runコンテナログから接続ログを確認（オプション）
  - _Requirements: 3.4_

- [x] 7.6 DNS解決とLoad Balancerテストの実装
  - domain_nameとload_balancer_ip出力値を取得
  - DNSルックアップを実行してAレコードを検証
  - Load Balancer IPアドレスとの一致を確認
  - Cloud Armorセキュリティポリシーの適用を検証
  - 許可されていないIPアドレスからのアクセスが403で拒否されることを確認（オプション）
  - _Requirements: 3.5_

- [x] 7.7 テストREADMEとドキュメントの作成
  - test/gcp/README.mdを作成
  - テスト実行に必要な環境変数を説明
  - テスト実行手順を記載（go test -v ./gcp -timeout 60m）
  - テスト前提条件を記載（GCPプロジェクト、DNS Managed Zone、認証情報）
  - テスト失敗時のトラブルシューティングを追加
  - _Requirements: 3.7, 3.8_

- [x] 8. プロジェクト構造の更新とドキュメント整備
- [x] 8.1 プロジェクト構造ドキュメントの更新
  - `.kiro/steering/structure.md`を更新
  - GCPディレクトリ構造を追加（modules/gcp/cloud-run/、examples/gcp-cloud-run/、test/gcp/）
  - ファイル構成説明を追加
  - 機能別ファイル分割パターンの説明を追加
  - AWS実装との対照を記載
  - _Requirements: 4.7_

- [x] 8.2 技術スタックドキュメントの更新
  - `.kiro/steering/tech.md`を更新
  - GCP技術スタックセクションを追加（Cloud Run、Cloud Load Balancing、Cloud DNS等）
  - Bridgeコンテナイメージ情報を追加（ghcr.io/basemachina/bridge）
  - 環境変数とポート設定を記載
  - ネットワーク要件を追加（VPC Egress、Cloud SQL接続）
  - _Requirements: 6.1_

- [x] 8.3 ルートREADMEの更新
  - GCPサポートに関する情報を追加
  - Cloud Runモジュールへのリンクを追加
  - マルチクラウド対応の説明を更新
  - 使用例セクションにGCPを追加
  - _Requirements: 4.6_

- [x] 9. エンドツーエンド検証と統合テスト
- [x] 9.1 完全なデプロイフローの検証
  - 新しいGCPプロジェクトでExampleをデプロイ
  - すべてのリソースが正常に作成されることを確認
  - terraform planで変更がないことを確認（冪等性）
  - terraform applyの実行時間を記録
  - _Requirements: All requirements_

- [x] 9.2 実際のワークフローでの動作確認
  - BaseMachinaのIPアドレスからのHTTPSアクセスを確認
  - Bridgeの認証機能が正常に動作することを確認
  - Cloud SQLへのクエリが成功することを確認
  - Cloud Loggingにログが出力されることを確認
  - オートスケーリングが動作することを確認（負荷テスト）
  - _Requirements: 1.2, 1.3, 1.4, 5.1, 5.8_

- [x] 9.3 クリーンアップとリソース削除の検証
  - terraform destroyですべてのリソースが削除されることを確認
  - 残存リソースがないことを確認（手動確認）
  - 削除失敗時のエラーハンドリングを確認
  - _Requirements: 3.6_

- [x] 10. 品質保証とベストプラクティスの最終確認
- [x] 10.1 コード品質の最終チェック
  - すべてのTerraformファイルでterraform fmtを実行
  - すべてのモジュールでterraform validateを実行
  - tfsecでセキュリティスキャンを実行し、問題がないことを確認
  - コメントとドキュメントの正確性を確認
  - _Requirements: 6.4, 6.5, 6.6_

- [x] 10.2 ドキュメントの最終レビュー
  - すべてのREADME.mdの正確性を確認
  - terraform.tfvars.exampleの設定値を確認
  - リンク切れがないことを確認
  - 手順が最新の実装と一致していることを確認
  - _Requirements: 4.6, 4.8_

- [x] 10.3 テストカバレッジの確認
  - すべての要件がテストでカバーされていることを確認
  - エッジケースのテストを追加（必要に応じて）
  - エラーハンドリングのテストを確認
  - テスト実行時間を最適化
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_
