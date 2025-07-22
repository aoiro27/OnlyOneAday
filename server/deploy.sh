#!/bin/bash

# GCP Cloud Functions デプロイスクリプト

# 設定
PROJECT_ID="yuusui-337412"
REGION="asia-northeast1"
FUNCTION_NAME="only-one-a-day-api"
RUNTIME="python311"
MEMORY="256MB"
TIMEOUT="60s"

# テスト関数のデプロイ（まず基本動作を確認）
echo "Deploying test function..."
gcloud functions deploy test-function \
    --gen2 \
    --runtime=$RUNTIME \
    --region=$REGION \
    --source=./test_function \
    --entry-point=test_function \
    --trigger-http \
    --allow-unauthenticated \
    --memory=$MEMORY \
    --timeout=$TIMEOUT

# メインAPI関数のデプロイ
echo "Deploying main API function..."
gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=$RUNTIME \
    --region=$REGION \
    --source=. \
    --entry-point=only_one_a_day_api \
    --trigger-http \
    --allow-unauthenticated \
    --memory=$MEMORY \
    --timeout=$TIMEOUT

# パートナー管理API関数のデプロイ
echo "Deploying partner management API function..."
gcloud functions deploy partner-management-api \
    --gen2 \
    --runtime=$RUNTIME \
    --region=$REGION \
    --source=./partner_management \
    --entry-point=partner_management_api \
    --trigger-http \
    --allow-unauthenticated \
    --memory=$MEMORY \
    --timeout=$TIMEOUT

echo "Deployment completed!"
echo "Test Function URL: https://$REGION-$PROJECT_ID.cloudfunctions.net/test-function"
echo "Main API URL: https://$REGION-$PROJECT_ID.cloudfunctions.net/$FUNCTION_NAME"
echo "Partner Management API URL: https://$REGION-$PROJECT_ID.cloudfunctions.net/partner-management-api" 