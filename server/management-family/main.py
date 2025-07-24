# main.py

import functions_framework
from google.cloud import firestore
import json

db = firestore.Client()

@functions_framework.http
def family_members_handler(request):
    try:
        # familyId, memberId の取得（クエリ or JSONボディ）
        family_id = request.args.get('familyId')
        member_id = request.args.get('memberId')
        if not family_id and request.method in ['POST', 'PUT', 'DELETE']:
            data = request.get_json(silent=True)
            family_id = data.get('familyId') if data else None
            if request.method in ['PUT', 'DELETE']:
                member_id = data.get('memberId') if data else None

        if not family_id:
            return ('familyId must be provided', 400)

        collection_path = f'family-management/{family_id}/members'

        if request.method == 'POST':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            name = data.get('name')
            device_token = data.get('deviceToken')  # deviceTokenパラメータを取得

            if not isinstance(name, str):
                return ('name must be a string', 400)

            # 作成データを準備
            create_data = {
                'name': name
            }
            
            # deviceTokenが提供されている場合は追加
            if device_token is not None:
                if not isinstance(device_token, str):
                    return ('deviceToken must be a string', 400)
                create_data['deviceToken'] = device_token

            doc_ref = db.collection(collection_path).add(create_data)
            response = {
                'result': 'created',
                'memberId': doc_ref[1].id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'PUT':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            member_id = member_id or data.get('memberId')
            name = data.get('name')
            device_token = data.get('deviceToken')  # deviceTokenパラメータを取得

            if not isinstance(member_id, str):
                return ('memberId must be provided as a string for update', 400)
            if not isinstance(name, str):
                return ('name must be a string', 400)

            doc_ref = db.collection(collection_path).document(member_id)
            if not doc_ref.get().exists:
                return ('Member not found', 404)

            # 更新データを準備
            update_data = {
                'name': name,
                'deviceToken': device_token
            }
            
            # deviceTokenが提供されている場合は追加
            if device_token is not None:
                if not isinstance(device_token, str):
                    return ('deviceToken must be a string', 400)
                update_data['deviceToken'] = device_token

            doc_ref.update(update_data)
            response = {
                'result': 'updated',
                'memberId': member_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'DELETE':
            member_id = member_id or (request.get_json(silent=True) or {}).get('memberId')
            if not isinstance(member_id, str):
                return ('memberId must be provided as a string for delete', 400)
            doc_ref = db.collection(collection_path).document(member_id)
            if not doc_ref.get().exists:
                return ('Member not found', 404)
            doc_ref.delete()
            response = {
                'result': 'deleted',
                'memberId': member_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'GET':
            docs = db.collection(collection_path).stream()
            result = []
            for doc in docs:
                doc_dict = doc.to_dict()
                doc_dict['memberId'] = doc.id
                result.append(doc_dict)
            return (json.dumps(result, ensure_ascii=False), 200, {'Content-Type': 'application/json'})

        else:
            return ('Method Not Allowed', 405)

    except Exception as e:
        return (json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'})

