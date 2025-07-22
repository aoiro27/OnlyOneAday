import functions_framework
from flask import jsonify

@functions_framework.http
def test_function(request):
    """シンプルなテスト用関数"""
    # CORS設定
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    return jsonify({
        'message': 'Test function is working!',
        'method': request.method,
        'path': request.path
    }), 200, headers 