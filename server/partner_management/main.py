import functions_framework
from flask import request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import uuid
import os

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
def partner_management_api(request):
    """パートナー管理用のAPIエンドポイント"""
    
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
        
        if path == 'api/partners/create':
            return create_partner(request, headers)
        elif path == 'api/partners/update':
            return update_partner(request, headers)
        elif path == 'api/partners/delete':
            return delete_partner(request, headers)
        elif path == 'api/partners/list':
            return list_partners(request, headers)
        else:
            # デフォルトのレスポンス（ヘルスチェック用）
            return jsonify({
                'message': 'Partner Management API is working!',
                'method': request.method,
                'path': path
            }), 200, headers
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500, headers

def create_partner(request, headers):
    """パートナーを作成"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        name = data.get('name')
        device_token = data.get('device_token')
        
        if not name:
            return jsonify({'error': 'Partner name is required'}), 400, headers
        
        # パートナーコードを生成
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
        
        # パートナーを作成
        partner_ref = db.collection('partners').document()
        partner_data = {
            'id': partner_ref.id,
            'name': name,
            'device_token': device_token,
            'partner_code': partner_code,
            'is_connected': False,
            'created_at': datetime.utcnow(),
            'last_updated': datetime.utcnow()
        }
        partner_ref.set(partner_data)
        
        return jsonify({
            'message': 'Partner created successfully',
            'partner_id': partner_ref.id,
            'partner_code': partner_code
        }), 200, headers
        
    except Exception as e:
        print(f"Error creating partner: {str(e)}")
        return jsonify({'error': 'Failed to create partner'}), 500, headers

def update_partner(request, headers):
    """パートナー情報を更新"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        partner_id = data.get('partner_id')
        name = data.get('name')
        device_token = data.get('device_token')
        
        if not partner_id:
            return jsonify({'error': 'Partner ID is required'}), 400, headers
        
        partner_ref = db.collection('partners').document(partner_id)
        partner_doc = partner_ref.get()
        
        if not partner_doc.exists:
            return jsonify({'error': 'Partner not found'}), 404, headers
        
        # 更新データを準備
        update_data = {
            'last_updated': datetime.utcnow()
        }
        
        if name:
            update_data['name'] = name
        if device_token:
            update_data['device_token'] = device_token
        
        partner_ref.update(update_data)
        
        return jsonify({'message': 'Partner updated successfully'}), 200, headers
        
    except Exception as e:
        print(f"Error updating partner: {str(e)}")
        return jsonify({'error': 'Failed to update partner'}), 500, headers

def delete_partner(request, headers):
    """パートナーを削除"""
    if request.method != 'POST':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        data = request.get_json()
        partner_id = data.get('partner_id')
        
        if not partner_id:
            return jsonify({'error': 'Partner ID is required'}), 400, headers
        
        partner_ref = db.collection('partners').document(partner_id)
        partner_doc = partner_ref.get()
        
        if not partner_doc.exists:
            return jsonify({'error': 'Partner not found'}), 404, headers
        
        partner_ref.delete()
        
        return jsonify({'message': 'Partner deleted successfully'}), 200, headers
        
    except Exception as e:
        print(f"Error deleting partner: {str(e)}")
        return jsonify({'error': 'Failed to delete partner'}), 500, headers

def list_partners(request, headers):
    """パートナー一覧を取得"""
    if request.method != 'GET':
        return jsonify({'error': 'Method not allowed'}), 405, headers
    
    try:
        partners_ref = db.collection('partners')
        partners = partners_ref.stream()
        
        partner_list = []
        for partner in partners:
            partner_data = partner.to_dict()
            partner_data['id'] = partner.id
            partner_list.append(partner_data)
        
        return jsonify({'partners': partner_list}), 200, headers
        
    except Exception as e:
        print(f"Error listing partners: {str(e)}")
        return jsonify({'error': 'Failed to list partners'}), 500, headers 