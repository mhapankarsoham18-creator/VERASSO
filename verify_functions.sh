#!/bin/bash
# Local Edge Function Verification Script

echo "🚀 Verifying Edge Functions locally..."

# 1. Validate Invite Code
echo "Testing validate-invite-code..."
curl -i --request POST 'http://localhost:54321/functions/v1/validate-invite-code' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{ "code": "INVALID-CODE" }'

# 2. Content Moderator
echo -e "\n\nTesting content-moderator..."
curl -i --request POST 'http://localhost:54321/functions/v1/content-moderator' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{ "content": "I like this project" }'

# 3. Rate Limiter
echo -e "\n\nTesting rate-limiter..."
curl -i --request POST 'http://localhost:54321/functions/v1/rate-limiter' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{ "endpoint": "/api/v1/posts" }'

echo -e "\n\n✅ Done!"
