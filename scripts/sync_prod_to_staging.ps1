# VERASSO Schema Sync: Prod -> Staging (PowerShell)

param (
    [Parameter(Mandatory=$false)]
    [string]$AccessToken = $env:SUPABASE_ACCESS_TOKEN,
    [Parameter(Mandatory=$false)]
    [string]$ProdRef = $env:PROD_PROJECT_REF,
    [Parameter(Mandatory=$false)]
    [string]$StagingRef = $env:STAGING_PROJECT_REF
)

if (-not $AccessToken -or -not $ProdRef -or -not $StagingRef) {
    Write-Error "Error: SUPABASE_ACCESS_TOKEN, PROD_PROJECT_REF, and STAGING_PROJECT_REF must be set or passed as arguments."
    exit 1
}

Write-Host "--- VERASSO Schema Sync: Prod -> Staging ---" -ForegroundColor Cyan

Write-Host "1. Linking to Production Project ($ProdRef)..."
npx supabase link --project-ref $ProdRef --access-token $AccessToken

Write-Host "2. Pulling schema from Production..."
npx supabase db pull --access-token $AccessToken

Write-Host "3. Linking to Staging Project ($StagingRef)..."
npx supabase link --project-ref $StagingRef --access-token $AccessToken

Write-Host "4. Pushing schema to Staging..."
npx supabase db push --access-token $AccessToken

Write-Host "Success: Staging schema is now in sync with Production." -ForegroundColor Green
