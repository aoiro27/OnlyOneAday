import functions_framework
from google.cloud import firestore
import json

db = firestore.Client()

@functions_framework.http
def user_goals_handler(request):
    try:
        # userId, goalId の取得（クエリ or JSONボディ）
        user_id = request.args.get('userId')
        goal_id = request.args.get('goalId')
        if not user_id and request.method in ['POST', 'PUT', 'DELETE']:
            data = request.get_json(silent=True)
            user_id = data.get('userId') if data else None
            if request.method in ['PUT', 'DELETE']:
                goal_id = data.get('goalId') if data else None

        if not user_id:
            return ('userId must be provided', 400)

        collection_path = f'user-goals/{user_id}/goals'

        if request.method == 'POST':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            # Goalデータ例: title, detail, isCompleted, createdAt など
            title = data.get('title')
            detail = data.get('detail')
            is_completed = data.get('isCompleted', False)
            created_at = data.get('createdAt')

            if not isinstance(title, str):
                return ('title must be a string', 400)

            create_data = {
                'title': title,
                'detail': detail,
                'isCompleted': is_completed,
                'createdAt': created_at
            }
            doc_ref = db.collection(collection_path).add(create_data)
            response = {
                'result': 'created',
                'goalId': doc_ref[1].id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'PUT':
            data = request.get_json(silent=True)
            if not data:
                return ('No JSON payload provided', 400)

            goal_id = goal_id or data.get('goalId')
            title = data.get('title')
            detail = data.get('detail')
            is_completed = data.get('isCompleted')
            created_at = data.get('createdAt')

            if not isinstance(goal_id, str):
                return ('goalId must be provided as a string for update', 400)
            if title is not None and not isinstance(title, str):
                return ('title must be a string', 400)

            doc_ref = db.collection(collection_path).document(goal_id)
            if not doc_ref.get().exists:
                return ('Goal not found', 404)

            update_data = {}
            if title is not None:
                update_data['title'] = title
            if detail is not None:
                update_data['detail'] = detail
            if is_completed is not None:
                update_data['isCompleted'] = is_completed
            if created_at is not None:
                update_data['createdAt'] = created_at

            doc_ref.update(update_data)
            response = {
                'result': 'updated',
                'goalId': goal_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'DELETE':
            goal_id = goal_id or (request.get_json(silent=True) or {}).get('goalId')
            if not isinstance(goal_id, str):
                return ('goalId must be provided as a string for delete', 400)
            doc_ref = db.collection(collection_path).document(goal_id)
            if not doc_ref.get().exists:
                return ('Goal not found', 404)
            doc_ref.delete()
            response = {
                'result': 'deleted',
                'goalId': goal_id
            }
            return (json.dumps(response), 200, {'Content-Type': 'application/json'})

        elif request.method == 'GET':
            docs = db.collection(collection_path).stream()
            result = []
            for doc in docs:
                doc_dict = doc.to_dict()
                doc_dict['goalId'] = doc.id
                result.append(doc_dict)
            
            # 作成日時順にソート（新しい順）
            result.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
            
            return (json.dumps(result, ensure_ascii=False), 200, {'Content-Type': 'application/json'})

        else:
            return ('Method Not Allowed', 405)

    except Exception as e:
        return (json.dumps({'error': str(e)}), 500, {'Content-Type': 'application/json'}) 