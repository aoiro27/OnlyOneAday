# OnlyOneAday Server (GCP Cloud Functions)

OnlyOneAdayアプリのサーバーサイド実装です。GCP Cloud Functionsで動作し、Firebase Cloud Messagingを使用してプッシュ通知を送信します。

## 🚀 機能

- **デバイストークン管理**: APNsデバイストークンの登録・管理
- **パートナー管理**: パートナーの作成・更新・削除・接続
- **プッシュ通知**: 目標達成時のパートナー通知
- **ファミリー目標通知**: ファミリー目標達成時の通知

## 📁 ファイル構成

```
server/
├── main.py                    # メインAPI関数
├── partner_management.py      # パートナー管理API
├── firebase_config.py         # Firebase設定
├── requirements.txt           # Python依存関係
├── deploy.sh                  # デプロイスクリプト
├── test_local.py             # ローカルテストスクリプト
├── env.example               # 環境変数設定例
└── README.md                 # このファイル
```

## 🛠️ セットアップ

### 1. GCPプロジェクトの準備

1. [Google Cloud Console](https://console.cloud.google.com/)でプロジェクトを作成
2. 以下のAPIを有効化：
   - Cloud Functions API
   - Cloud Build API
   - Firebase Admin SDK

### 2. Firebaseプロジェクトの準備

1. [Firebase Console](https://console.firebase.google.com/)でプロジェクトを作成
2. Firestore Databaseを作成
3. Cloud Messagingを有効化
4. iOSアプリを追加し、APNs証明書をアップロード

### 3. サービスアカウントキーの作成

1. GCP Console → IAM & Admin → Service Accounts
2. 新しいサービスアカウントを作成
3. 以下の権限を付与：
   - Cloud Functions Developer
   - Firebase Admin
4. JSONキーをダウンロード

### 4. 環境変数の設定

`env.example`を参考に、以下の環境変数を設定：

```bash
export GCP_PROJECT_ID="your-gcp-project-id"
export FIREBASE_SERVICE_ACCOUNT_PATH="path/to/service-account-key.json"
export FUNCTION_REGION="asia-northeast1"
```

## 🚀 デプロイ

### 1. gcloud CLIのインストール

```bash
# macOS
brew install google-cloud-sdk

# 初期化
gcloud init
gcloud auth application-default login
```

### 2. デプロイスクリプトの実行

```bash
# デプロイスクリプトを編集してPROJECT_IDを設定
vim deploy.sh

# 実行権限を付与
chmod +x deploy.sh

# デプロイ実行
./deploy.sh
```

### 3. 手動デプロイ

```bash
# メインAPI関数
gcloud functions deploy only-one-a-day-api \
    --gen2 \
    --runtime=python311 \
    --region=asia-northeast1 \
    --source=. \
    --entry-point=only_one_a_day_api \
    --trigger=http \
    --allow-unauthenticated

# パートナー管理API関数
gcloud functions deploy partner-management-api \
    --gen2 \
    --runtime=python311 \
    --region=asia-northeast1 \
    --source=. \
    --entry-point=partner_management_api \
    --trigger=http \
    --allow-unauthenticated
```

## 🧪 ローカルテスト

### 1. 依存関係のインストール

```bash
pip install -r requirements.txt
```

### 2. ローカルサーバーの起動

```bash
# メインAPI関数
functions-framework --target=only_one_a_day_api --port=8080

# 別ターミナルでパートナー管理API関数
functions-framework --target=partner_management_api --port=8081
```

### 3. テストの実行

```bash
python test_local.py
```

## 📡 API エンドポイント

### メインAPI (`main.py`)

| エンドポイント | メソッド | 説明 |
|---------------|----------|------|
| `/api/register_device_token` | POST | デバイストークン登録 |
| `/api/notify_partner` | POST | パートナー通知 |
| `/api/notify_family_goal` | POST | ファミリー目標通知 |
| `/api/connect_partner` | POST | パートナー接続 |
| `/api/generate_partner_code` | POST | パートナーコード生成 |

### パートナー管理API (`partner_management.py`)

| エンドポイント | メソッド | 説明 |
|---------------|----------|------|
| `/api/partners/create` | POST | パートナー作成 |
| `/api/partners/update` | POST | パートナー更新 |
| `/api/partners/delete` | POST | パートナー削除 |
| `/api/partners/list` | GET | パートナー一覧 |

## 🔧 アプリ側の設定

デプロイ後、アプリ側の`APIConfig.swift`でサーバーURLを更新：

```swift
static let developmentBaseURL = "https://asia-northeast1-your-project-id.cloudfunctions.net/only-one-a-day-api"
static let productionBaseURL = "https://asia-northeast1-your-project-id.cloudfunctions.net/only-one-a-day-api"
```

## 📊 Firestore コレクション構造

### devices
```
{
  "device_token": "string",
  "platform": "ios",
  "app_version": "1.0.0",
  "created_at": "timestamp",
  "last_updated": "timestamp"
}
```

### partners
```
{
  "id": "string",
  "name": "string",
  "device_token": "string",
  "partner_code": "string",
  "is_connected": "boolean",
  "created_at": "timestamp",
  "last_updated": "timestamp"
}
```

### notifications
```
{
  "partner_id": "string",
  "goal_title": "string",
  "goal_type": "string",
  "timestamp": "string",
  "type": "string",
  "message_id": "string"
}
```

## 🔒 セキュリティ

- CORS設定でクロスオリジンリクエストを許可
- Firebase Admin SDKで認証
- 環境変数で機密情報を管理

## 🐛 トラブルシューティング

### よくある問題

1. **デプロイエラー**
   - gcloud CLIが最新版か確認
   - プロジェクトIDが正しく設定されているか確認

2. **プッシュ通知が届かない**
   - APNs証明書が正しく設定されているか確認
   - デバイストークンが正しく登録されているか確認

3. **Firestore接続エラー**
   - サービスアカウントキーが正しく設定されているか確認
   - Firestoreが有効化されているか確認

## 📞 サポート

問題が発生した場合は、以下を確認してください：

1. Cloud Functionsのログ
2. Firebase Consoleのログ
3. アプリ側のコンソールログ 