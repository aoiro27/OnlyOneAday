import json
import jwt
import time
import httpx
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import functions_framework

import os

# APNs設定（環境変数から取得）
TEAM_ID = os.environ.get('TEAM_ID') # Apple Developer Team ID
KEY_ID = os.environ.get('KEY_ID')     # APNs認証キーのID
BUNDLE_ID = os.environ.get('BUNDLE_ID')  # アプリのBundle ID

# デバイストークン（固定値 - 勉強用）
DEVICE_TOKEN = os.environ.get('DEVICE_TOKEN') 


APNS_URL = "https://api.sandbox.push.apple.com/3/device/"

# プライベートキーファイルパス
PRIVATE_KEY_PATH = os.environ.get('PRIVATE_KEY_PATH') 

def create_jwt_token():
    """
    APNs用のJWTトークンを作成
    """
    try:
        # プライベートキーを読み込み
        with open(PRIVATE_KEY_PATH, 'r') as key_file:
            private_key = key_file.read()
            print("privatekey")
            print(private_key)
        # プライベートキーをデコード
        key = serialization.load_pem_private_key(
            private_key.encode('utf-8'),
            password=None,
            backend=default_backend()
        )
        
        # JWTペイロードを作成
        payload = {
            'iss': TEAM_ID,
            'iat': int(time.time())
        }
        
        # JWTトークンを生成
        token = jwt.encode(
            payload,
            key,
            algorithm='ES256',
            headers={
                'kid': KEY_ID,
                'alg': 'ES256'
            }
        )
        
        return token
    
    except Exception as e:
        print(f"JWTトークン作成エラー: {e}")
        return None

def send_push_notification(device_token, title, body, badge=None, sound="default"):
    """
    APNsプッシュ通知を送信（HTTP/2対応）
    """
    try:
        # デバッグ情報を出力
        print(f"🔧 デバッグ情報:")
        print(f"  - APNS_URL: {APNS_URL}")
        print(f"  - BUNDLE_ID: {BUNDLE_ID}")
        print(f"  - TEAM_ID: {TEAM_ID}")
        print(f"  - KEY_ID: {KEY_ID}")
        print(f"  - DEVICE_TOKEN: {device_token[:20]}...{device_token[-20:]}")
        
        # JWTトークンを取得
        jwt_token = create_jwt_token()
        if not jwt_token:
            return {"success": False, "error": "JWTトークンの作成に失敗しました"}
        
        # ヘッダーを設定
        headers = {
            'Authorization': f'bearer {jwt_token}',
            'apns-topic': BUNDLE_ID,
            'Content-Type': 'application/json'
        }
        
        print(f"  - Headers: {headers}")
        
        # ペイロードを作成
        payload = {
            'aps': {
                'alert': {
                    'title': title,
                    'body': body
                },
                'badge': badge,
                'sound': sound,
                "content-available": 1
            }
        }
        
        print(f"  - Payload: {payload}")
        
        # HTTP/2でリクエストを送信
        url = f"{APNS_URL}{device_token}"
        print(f"  - Request URL: {url}")
        
        # httpxクライアントを作成
        # 注意: APNsはHTTP/2のみをサポートするため、http2=Trueが必要
        # ただし、依存関係の問題がある場合は一時的にhttp2=Falseでテスト可能
        try:
            with httpx.Client(
                http2=True, 
                timeout=30.0,
                limits=httpx.Limits(max_keepalive_connections=5, max_connections=10)
            ) as client:
                response = client.post(
                    url,
                    headers=headers,
                    json=payload
                )
        except Exception as http2_error:
            # HTTP/2が利用できない場合のエラーハンドリング
            return {
                "success": False,
                "error": f"HTTP/2接続エラー: {str(http2_error)}",
                "note": "APNsはHTTP/2のみをサポートします。httpx[http2]の依存関係を確認してください。"
            }
        
        print(f"  - Response Status: {response.status_code}")
        print(f"  - Response Protocol: {response.http_version}")
        print(f"  - Response Headers: {dict(response.headers)}")
        print(f"  - Response Body: {response.text}")
        
        if response.status_code == 200:
            return {
                "success": True,
                "message": "プッシュ通知が正常に送信されました",
                "status_code": response.status_code,
                "protocol": response.http_version
            }
        else:
            return {
                "success": False,
                "error": f"プッシュ通知の送信に失敗しました: {response.status_code}",
                "response": response.text,
                "protocol": response.http_version,
                "debug_info": {
                    "bundle_id": BUNDLE_ID,
                    "team_id": TEAM_ID,
                    "key_id": KEY_ID,
                    "device_token_length": len(device_token)
                }
            }
    
    except Exception as e:
        return {
            "success": False,
            "error": f"エラーが発生しました: {str(e)}"
        }

@functions_framework.http
def send_apns_push(request):

    # CORSヘッダーを設定
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
  
        # デフォルト値を使用
        title = "テスト通知"
        body = "これはテスト用のプッシュ通知です"
        badge = 1
        sound = "default"
        device_token = DEVICE_TOKEN
        
        # プッシュ通知を送信
        result = send_push_notification(device_token, title, body, badge, sound)
        
        return (json.dumps(result, ensure_ascii=False), 200, headers)
    
    except Exception as e:
        error_result = {
            "success": False,
            "error": f"関数実行エラー: {str(e)}"
        }
        return (json.dumps(error_result, ensure_ascii=False), 500, headers)

