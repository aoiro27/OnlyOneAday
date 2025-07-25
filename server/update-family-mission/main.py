# main.py

import functions_framework
from google.cloud import firestore
import json

db = firestore.Client()

@functions_framework.http
def family_missions_handler(request):
    try:
        # familyIdの取得（クエリ or JSONボディ）
        family_id = request.args.get('familyId')
        doc_id = request.args.get('doc_id')
        if not family_id and request.method in ['POST', 'PUT', 'DELETE']:
            data = request.get_json(silent=True)
            family_id = data.get('familyId') if data else None
            if request.method == 'DELETE':
                doc_id = data.get('doc_id') if data else None

        if not family_id:
            return ('familyId must be provided', 400)

        collection_path = f'family-management/{family_id}/missions'

        if request.method == 'POST':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            is_cleared = data.get('isCleared')
            mission = data.get('mission')
            created_at = data.get('createdAt')

            if not isinstance(is_cleared, bool):
                return ('isCleared must be a boolean', 400)
            if not isinstance(mission, str):
                return ('mission must be a string', 400)

            create_data = {
                'isCleared': is_cleared,
                'mission': mission,
                'createdAt': created_at
            }
            doc_ref = db.collection(collection_path).add(create_data)
            response = {
                'result': 'created',
                'doc_id': doc_ref[1].id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'PUT':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            is_cleared = data.get('isCleared')
            mission = data.get('mission')
            doc_id = data.get('doc_id')

            if not isinstance(is_cleared, bool):
                return ('isCleared must be a boolean', 400)
            if not isinstance(mission, str):
                return ('mission must be a string', 400)
            if not isinstance(doc_id, str):
                return ('doc_id must be provided as a string for update', 400)

            doc_ref = db.collection(collection_path).document(doc_id)
            if not doc_ref.get().exists:
                return ('Document not found', 404)

            doc_ref.update({
                'isCleared': is_cleared,
                'mission': mission
            })
            response = {
                'result': 'updated',
                'doc_id': doc_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'GET':
            docs = db.collection(collection_path).stream()
            result = []
            for doc in docs:
                doc_dict = doc.to_dict()
                doc_dict['doc_id'] = doc.id
                result.append(doc_dict)
            
            # 作成日時順にソート（新しい順）
            result.sort(key=lambda x: x.get('createdAt', ''), reverse=false)
            
            return (json.dumps(result, ensure_ascii=False), 200, {'Content-Type': 'application/json'})

        elif request.method == 'DELETE':
            if not doc_id or not isinstance(doc_id, str):
                return ('doc_id must be provided as a string for delete', 400)
            doc_ref = db.collection(collection_path).document(doc_id)
            if not doc_ref.get().exists:
                return ('Document not found', 404)
            doc_ref.delete()
            response = {
                'result': 'deleted',
                'doc_id': doc_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        else:
            return ('Method Not Allowed', 405)

    except Exception as e:
        return (json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'})
