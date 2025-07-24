import json
import jwt
import time
import httpx
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import functions_framework
from google.cloud import firestore

import os

# APNs設定（環境変数から取得）
TEAM_ID = os.environ.get('TEAM_ID') # Apple Developer Team ID
KEY_ID = os.environ.get('KEY_ID')     # APNs認証キーのID
BUNDLE_ID = os.environ.get('BUNDLE_ID')  # アプリのBundle ID

# デバイストークン（固定値 - 勉強用）
DEVICE_TOKEN = os.environ.get('DEVICE_TOKEN') 

# Firestoreクライアント
db = firestore.Client()

APNS_URL = "https://api.sandbox.push.apple.com/3/device/"

# プライベートキーファイルパス
PRIVATE_KEY_PATH = os.environ.get('PRIVATE_KEY_PATH')

def get_family_member_device_tokens(family_id, exclude_member_id=None):
    """
    ファミリーメンバーのデバイストークンを取得（自分以外）
    """
    try:
        collection_path = f'family-management/{family_id}/members'
        docs = db.collection(collection_path).stream()
        
        device_tokens = []
        for doc in docs:
            doc_data = doc.to_dict()
            member_id = doc.id
            
            # 自分以外のメンバーのデバイストークンを取得
            if exclude_member_id is None or member_id != exclude_member_id:
                if 'deviceToken' in doc_data and doc_data['deviceToken']:
                    device_tokens.append({
                        'memberId': member_id,
                        'name': doc_data.get('name', 'Unknown'),
                        'deviceToken': doc_data['deviceToken']
                    })
        
        print(f"🔧 ファミリーメンバーのデバイストークン取得:")
        print(f"  - family_id: {family_id}")
        print(f"  - exclude_member_id: {exclude_member_id}")
        print(f"  - found_tokens: {len(device_tokens)}")
        
        return device_tokens
    
    except Exception as e:
        print(f"❌ デバイストークン取得エラー: {e}")
        return []

def create_jwt_token():
    """
    APNs用のJWTトークンを作成
    """
    try:
        print(f"🔧 JWTトークン作成開始:")
        print(f"  - PRIVATE_KEY_PATH: {PRIVATE_KEY_PATH}")
        print(f"  - TEAM_ID: {TEAM_ID}")
        print(f"  - KEY_ID: {KEY_ID}")
        
        # 環境変数の確認
        if not PRIVATE_KEY_PATH:
            print("❌ PRIVATE_KEY_PATHが設定されていません")
            return None
        if not TEAM_ID:
            print("❌ TEAM_IDが設定されていません")
            return None
        if not KEY_ID:
            print("❌ KEY_IDが設定されていません")
            return None
        
        # プライベートキーを読み込み
        with open(PRIVATE_KEY_PATH, 'r') as key_file:
            private_key = key_file.read()
            print(f"  - プライベートキー読み込み成功: {len(private_key)}文字")
        
        # プライベートキーをデコード
        key = serialization.load_pem_private_key(
            private_key.encode('utf-8'),
            password=None,
            backend=default_backend()
        )
        print("  - プライベートキーデコード成功")
        
        # JWTペイロードを作成
        current_time = int(time.time())
        payload = {
            'iss': TEAM_ID,
            'iat': current_time
        }
        print(f"  - JWTペイロード作成: {payload}")
        
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
        
        print(f"  - JWTトークン生成成功: {len(token)}文字")
        return token
    
    except FileNotFoundError as e:
        print(f"❌ プライベートキーファイルが見つかりません: {e}")
        return None
    except Exception as e:
        print(f"❌ JWTトークン作成エラー: {e}")
        print(f"  - エラータイプ: {type(e).__name__}")
        import traceback
        print(f"  - スタックトレース: {traceback.format_exc()}")
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
            print("❌ JWTトークンの作成に失敗しました")
            return {"success": False, "error": "JWTトークンの作成に失敗しました"}
        
        print(f"  - JWTトークン取得成功: {len(jwt_token)}文字")
        
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

def send_push_notifications_to_family(family_id, exclude_member_id, title, body, badge=None, sound="default"):
    """
    ファミリーメンバー全員にプッシュ通知を送信（自分以外）
    """
    try:
        # ファミリーメンバーのデバイストークンを取得
        device_tokens = get_family_member_device_tokens(family_id, exclude_member_id)
        
        if not device_tokens:
            return {
                "success": True,
                "message": "送信対象のデバイストークンが見つかりませんでした",
                "sent_count": 0
            }
        
        # 各デバイストークンに通知を送信
        success_count = 0
        failed_count = 0
        results = []
        
        print(f"🔧 プッシュ通知送信開始:")
        print(f"  - 送信対象数: {len(device_tokens)}")
        print(f"  - 通知タイトル: {title}")
        print(f"  - 通知本文: {body}")
        
        for i, token_info in enumerate(device_tokens):
            print(f"  - 送信 {i+1}/{len(device_tokens)}: {token_info['name']} ({token_info['memberId']})")
            result = send_push_notification(
                token_info['deviceToken'], 
                title, 
                body, 
                badge, 
                sound
            )
            
            if result.get('success', False):
                success_count += 1
            else:
                failed_count += 1
            
            results.append({
                'memberId': token_info['memberId'],
                'name': token_info['name'],
                'result': result
            })
        
        return {
            "success": True,
            "message": f"プッシュ通知送信完了: 成功 {success_count}件, 失敗 {failed_count}件",
            "sent_count": success_count,
            "failed_count": failed_count,
            "total_count": len(device_tokens),
            "results": results
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": f"ファミリー通知送信エラー: {str(e)}"
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

@functions_framework.http
def send_family_goal_notification(request):
    """
    目標達成時にファミリーメンバーにプッシュ通知を送信
    """
    # CORSヘッダーを設定
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
        if request.method != 'POST':
            return (json.dumps({"error": "POST method only"}), 405, headers)
        
        data = request.get_json(silent=True)
        if not data:
            return (json.dumps({"error": "No JSON payload provided"}), 400, headers)
        
        # 必須パラメータの取得
        family_id = data.get('familyId')
        member_id = data.get('memberId')
        member_name = data.get('memberName', 'ファミリーメンバー')
        goal_title = data.get('goalTitle', '目標')
        
        if not family_id or not member_id:
            return (json.dumps({"error": "familyId and memberId are required"}), 400, headers)
        
        # 通知の内容を設定
        title = "🎉 目標達成！"
        body = f"{member_name}が「{goal_title}」を達成しました！"
        badge = 1
        sound = "default"
        
        # ファミリーメンバーに通知を送信
        result = send_push_notifications_to_family(
            family_id, 
            member_id, 
            title, 
            body, 
            badge, 
            sound
        )
        
        return (json.dumps(result, ensure_ascii=False), 200, headers)
    
    except Exception as e:
        error_result = {
            "success": False,
            "error": f"関数実行エラー: {str(e)}"
        }
        return (json.dumps(error_result, ensure_ascii=False), 500, headers)

