import functions_framework
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import os
import json
from datetime import datetime
import uuid

# Firebase初期化
try:
    if not firebase_admin._apps:
        # 本番環境では環境変数から認証情報を取得
        if os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
            cred = credentials.ApplicationDefault()
        else:
            # 開発環境用（ローカルテスト時）
            cred = credentials.Certificate('path/to/service-account-key.json')
        
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
except Exception as e:
    print(f"Firebase initialization error: {e}")
    db = None

@functions_framework.http
def only_one_a_day_api(request):
    """OnlyOneAday API のメインエンドポイント"""
    
    # CORS設定
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
    }
    
    try:
        # Firebase初期化チェック
        if db is None:
            return jsonify({'error': 'Firebase not initialized'}), 500, headers
        
        # パスに基づいてルーティング
        path = request.path.strip('/')
        
        if path == 'api/register_device_token':
            return register_device_token(request, headers)
        elif path == 'api/notify_partner':
            return notify_partner(request, headers)
        elif path == 'api/notify_family_goal':
            return notify_family_goal(request, headers)
        elif path == 'api/connect_partner':
            return connect_partner(request, headers)
        elif path == 'api/generate_partner_code':
            return generate_partner_code(request, headers)
        else:
            # デフォルトのレスポンス（ヘルスチェック用）
            return jsonify({
                'message': 'OnlyOneAday API is working!',
                'method': request.method,
                'path': path
            }), 200, headers
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500, headers

def register_device_token(request, headers):
    """デバイストークンを登録"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        device_token = data.get('device_token')
        platform = data.get('platform', 'ios')
        app_version = data.get('app_version', '1.0.0')
        
        if not device_token:
            return jsonify({'error': 'Device token is required'}), 400, headers
        
        # デバイストークンをFirestoreに保存
        device_ref = db.collection('devices').document(device_token)
        device_data = {
            'device_token': device_token,
            'platform': platform,
            'app_version': app_version,
            'created_at': datetime.utcnow(),
            'last_updated': datetime.utcnow()
        }
        device_ref.set(device_data)
        
        return jsonify({'message': 'Device token registered successfully'}), 200, headers
        
    except Exception as e:
        print(f"Error registering device token: {str(e)}")
        return jsonify({'error': 'Failed to register device token'}), 500, headers

def notify_partner(request, headers):
    """パートナーに目標達成通知を送信"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        partner_id = data.get('partner_id')
        goal_title = data.get('goal_title')
        goal_type = data.get('goal_type', 'personal')
        timestamp = data.get('timestamp')
        
        if not partner_id or not goal_title:
            return jsonify({'error': 'Partner ID and goal title are required'}), 400, headers
        
        # パートナーのデバイストークンを取得
        partner_ref = db.collection('partners').document(partner_id)
        partner_doc = partner_ref.get()
        
        if not partner_doc.exists:
            return jsonify({'error': 'Partner not found'}), 404, headers
        
        partner_data = partner_doc.to_dict()
        partner_device_token = partner_data.get('device_token')
        partner_name = partner_data.get('name', 'パートナー')
        
        if not partner_device_token:
            return jsonify({'error': 'Partner device token not found'}), 404, headers
        
        # プッシュ通知を送信
        message = messaging.Message(
            notification=messaging.Notification(
                title='🎉 パートナーの目標達成！',
                body=f'{partner_name}さんが「{goal_title}」を達成しました！おめでとうございます！'
            ),
            data={
                'goal_title': goal_title,
                'goal_type': goal_type,
                'timestamp': timestamp or datetime.utcnow().isoformat(),
                'type': 'partner_goal_completion'
            },
            token=partner_device_token
        )
        
        response = messaging.send(message)
        print(f'Successfully sent message: {response}')
        
        # 通知履歴を保存
        notification_ref = db.collection('notifications').document()
        notification_data = {
            'partner_id': partner_id,
            'goal_title': goal_title,
            'goal_type': goal_type,
            'timestamp': timestamp or datetime.utcnow().isoformat(),
            'type': 'partner_goal_completion',
            'message_id': response
        }
        notification_ref.set(notification_data)
        
        return jsonify({'message': 'Notification sent successfully', 'message_id': response}), 200, headers
        
    except Exception as e:
        print(f"Error sending partner notification: {str(e)}")
        return jsonify({'error': 'Failed to send notification'}), 500, headers

def notify_family_goal(request, headers):
    """ファミリー目標達成通知を送信"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        goal_title = data.get('goal_title')
        timestamp = data.get('timestamp')
        
        if not goal_title:
            return jsonify({'error': 'Goal title is required'}), 400, headers
        
        # ファミリー目標に関連するパートナーのデバイストークンを取得
        partners_ref = db.collection('partners')
        partners = partners_ref.where('is_connected', '==', True).stream()
        
        device_tokens = []
        for partner in partners:
            partner_data = partner.to_dict()
            if partner_data.get('device_token'):
                device_tokens.append(partner_data['device_token'])
        
        if not device_tokens:
            return jsonify({'error': 'No connected partners found'}), 404, headers
        
        # 複数のデバイスにプッシュ通知を送信
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title='🎉 ファミリー目標達成！',
                body=f'ファミリー目標「{goal_title}」を達成しました！家族みんなで協力してくれてありがとう！'
            ),
            data={
                'goal_title': goal_title,
                'timestamp': timestamp or datetime.utcnow().isoformat(),
                'type': 'family_goal_completion'
            },
            tokens=device_tokens
        )
        
        response = messaging.send_multicast(message)
        print(f'Successfully sent {response.success_count} messages')
        
        # 通知履歴を保存
        notification_ref = db.collection('notifications').document()
        notification_data = {
            'goal_title': goal_title,
            'timestamp': timestamp or datetime.utcnow().isoformat(),
            'type': 'family_goal_completion',
            'success_count': response.success_count,
            'failure_count': response.failure_count
        }
        notification_ref.set(notification_data)
        
        return jsonify({
            'message': 'Family goal notification sent successfully',
            'success_count': response.success_count,
            'failure_count': response.failure_count
        }), 200, headers
        
    except Exception as e:
        print(f"Error sending family goal notification: {str(e)}")
        return jsonify({'error': 'Failed to send family goal notification'}), 500, headers

def connect_partner(request, headers):
    """パートナーとの接続を確立"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        partner_code = data.get('partner_code')
        
        if not partner_code:
            return jsonify({'error': 'Partner code is required'}), 400, headers
        
        # パートナーコードでパートナーを検索
        partners_ref = db.collection('partners')
        partners = partners_ref.where('partner_code', '==', partner_code).stream()
        
        partner_doc = None
        for doc in partners:
            partner_doc = doc
            break
        
        if not partner_doc:
            return jsonify({'error': 'Invalid partner code'}), 404, headers
        
        partner_data = partner_doc.to_dict()
        
        # 接続状態を更新
        partner_doc.reference.update({
            'is_connected': True,
            'last_sync_date': datetime.utcnow()
        })
        
        return jsonify({
            'message': 'Partner connected successfully',
            'partner_id': partner_doc.id,
            'partner_name': partner_data.get('name')
        }), 200, headers
        
    except Exception as e:
        print(f"Error connecting partner: {str(e)}")
        return jsonify({'error': 'Failed to connect partner'}), 500, headers

def generate_partner_code(request, headers):
    """パートナーコードを生成"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        # 8文字のランダムなパートナーコードを生成
        import random
        import string
        
        letters = string.ascii_uppercase + string.digits
        partner_code = ''.join(random.choice(letters) for _ in range(8))
        
        # パートナーコードが重複しないように確認
        while True:
            partners_ref = db.collection('partners')
            existing = partners_ref.where('partner_code', '==', partner_code).limit(1).stream()
            
            if not list(existing):
                break
            
            partner_code = ''.join(random.choice(letters) for _ in range(8))
        
        return jsonify({'partner_code': partner_code}), 200, headers
        
    except Exception as e:
        print(f"Error generating partner code: {str(e)}")
        return jsonify({'error': 'Failed to generate partner code'}), 500, headers 