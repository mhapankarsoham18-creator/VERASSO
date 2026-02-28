#!/bin/bash

# Configuration: Ensure environment variables are set
# SUPABASE_ACCESS_TOKEN: Your personal access token
# PROD_PROJECT_REF: The reference ID of your production project
# STAGING_PROJECT_REF: The reference ID of your staging project

if [ -z "$SUPABASE_ACCESS_TOKEN" ] || [ -z "$PROD_PROJECT_REF" ] || [ -z "$STAGING_PROJECT_REF" ]; then
  echo "Error: SUPABASE_ACCESS_TOKEN, PROD_PROJECT_REF, and STAGING_PROJECT_REF must be set."
  exit 1
fi

echo "--- VERASSO Schema Sync: Prod -> Staging ---"

# Step 1: Link to Production to ensure we have the latest
echo "1. Linking to Production Project ($PROD_PROJECT_REF)..."
npx supabase link --project-ref "$PROD_PROJECT_REF" --access-token "$SUPABASE_ACCESS_TOKEN"

# Step 2: Pull schema from production. 
# This will create/update migrations in supabase/migrations
echo "2. Pulling schema from Production..."
npx supabase db pull --access-token "$SUPABASE_ACCESS_TOKEN"

# Step 3: Link to Staging
echo "3. Linking to Staging Project ($STAGING_PROJECT_REF)..."
npx supabase link --project-ref "$STAGING_PROJECT_REF" --access-token "$SUPABASE_ACCESS_TOKEN"

# Step 4: Push migrations to staging
echo "4. Pushing schema to Staging..."
npx supabase db push --access-token "$SUPABASE_ACCESS_TOKEN"

echo "Success: Staging schema is now in sync with Production."
echo "--------------------------------------------"
