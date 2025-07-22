#!/usr/bin/env python3
"""
ローカルテスト用スクリプト
"""

import requests
import json
import time

# ローカルサーバーのベースURL
BASE_URL = "http://localhost:8080"

def test_register_device_token():
    """デバイストークン登録のテスト"""
    print("Testing device token registration...")
    
    url = f"{BASE_URL}/api/register_device_token"
    data = {
        "device_token": "test_device_token_12345",
        "platform": "ios",
        "app_version": "1.0.0"
    }
    
    response = requests.post(url, json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_generate_partner_code():
    """パートナーコード生成のテスト"""
    print("Testing partner code generation...")
    
    url = f"{BASE_URL}/api/generate_partner_code"
    data = {}
    
    response = requests.post(url, json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()
    
    return response.json().get('partner_code')

def test_connect_partner(partner_code):
    """パートナー接続のテスト"""
    print("Testing partner connection...")
    
    url = f"{BASE_URL}/api/connect_partner"
    data = {
        "partner_code": partner_code
    }
    
    response = requests.post(url, json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_notify_partner():
    """パートナー通知のテスト"""
    print("Testing partner notification...")
    
    url = f"{BASE_URL}/api/notify_partner"
    data = {
        "partner_id": "test_partner_id",
        "goal_title": "テスト目標",
        "goal_type": "personal",
        "timestamp": "2024-01-01T12:00:00Z"
    }
    
    response = requests.post(url, json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_notify_family_goal():
    """ファミリー目標通知のテスト"""
    print("Testing family goal notification...")
    
    url = f"{BASE_URL}/api/notify_family_goal"
    data = {
        "goal_title": "ファミリー目標テスト",
        "timestamp": "2024-01-01T12:00:00Z"
    }
    
    response = requests.post(url, json=data)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def main():
    """メイン関数"""
    print("Starting local API tests...")
    print("=" * 50)
    
    try:
        # 各APIのテスト
        test_register_device_token()
        
        partner_code = test_generate_partner_code()
        if partner_code:
            test_connect_partner(partner_code)
        
        test_notify_partner()
        test_notify_family_goal()
        
        print("All tests completed!")
        
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to local server.")
        print("Make sure the Cloud Functions emulator is running:")
        print("functions-framework --target=only_one_a_day_api --port=8080")
    except Exception as e:
        print(f"Error during testing: {str(e)}")

if __name__ == "__main__":
    main() 