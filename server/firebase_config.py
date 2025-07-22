import os
import firebase_admin
from firebase_admin import credentials, firestore, messaging

class FirebaseConfig:
    """Firebase設定管理クラス"""
    
    @staticmethod
    def initialize_firebase():
        """Firebaseを初期化"""
        if not firebase_admin._apps:
            # 本番環境では環境変数から認証情報を取得
            if os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
                cred = credentials.ApplicationDefault()
            else:
                # 開発環境用（ローカルテスト時）
                # サービスアカウントキーファイルのパスを指定
                service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH', 'path/to/service-account-key.json')
                cred = credentials.Certificate(service_account_path)
            
            firebase_admin.initialize_app(cred)
        
        return firestore.client()
    
    @staticmethod
    def get_firestore_client():
        """Firestoreクライアントを取得"""
        return FirebaseConfig.initialize_firebase()
    
    @staticmethod
    def send_push_notification(token, title, body, data=None):
        """プッシュ通知を送信"""
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                token=token
            )
            
            response = messaging.send(message)
            print(f'Successfully sent message: {response}')
            return response
            
        except Exception as e:
            print(f'Error sending push notification: {str(e)}')
            raise
    
    @staticmethod
    def send_multicast_notification(tokens, title, body, data=None):
        """複数のデバイスにプッシュ通知を送信"""
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body
                ),
                data=data or {},
                tokens=tokens
            )
            
            response = messaging.send_multicast(message)
            print(f'Successfully sent {response.success_count} messages')
            return response
            
        except Exception as e:
            print(f'Error sending multicast notification: {str(e)}')
            raise 