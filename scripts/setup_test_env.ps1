# setup_test_env.ps1
# Automates the setup of local Supabase for integration testing.

Write-Host "🚀 Starting Local Test Environment Setup..." -ForegroundColor Cyan

# 1. Check for Supabase CLI
if (!(Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Error "❌ Supabase CLI not found. Please install it: https://supabase.com/docs/guides/cli"
    exit 1
}

# 2. Start Supabase (Internal Docker stack)
Write-Host "📦 Starting Supabase services (this may take a minute)..."
supabase start

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Failed to start Supabase. Ensure Docker is running."
    exit 1
}

# 3. Get Status and Extract Keys
Write-Host "🔑 Collecting local credentials..."
$status = supabase status --output json | ConvertFrom-Json

$apiUrl = $status.API_URL
$anonKey = $status.ANON_KEY
$serviceKey = $status.SERVICE_ROLE_KEY

# 4. Create .env.test
$targetFile = Join-Path $PSScriptRoot "..\.env.test"
$exampleFile = Join-Path $PSScriptRoot "..\.env.test.example"

if (Test-Path $exampleFile) {
    $content = Get-Content $exampleFile
    $content = $content -replace "SUPABASE_URL=.*", "SUPABASE_URL=$apiUrl"
    $content = $content -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=$anonKey"
    $content = $content -replace "SUPABASE_SERVICE_ROLE_KEY=.*", "SUPABASE_SERVICE_ROLE_KEY=$serviceKey"
    
    $content | Set-Content $targetFile
    Write-Host "✅ Created .env.test with local credentials." -ForegroundColor Green
} else {
    Write-Warning "⚠️ .env.test.example not found. Creating basic .env.test..."
    "SUPABASE_URL=$apiUrl`nSUPABASE_ANON_KEY=$anonKey`nSUPABASE_SERVICE_ROLE_KEY=$serviceKey`nSUPABASE_TEST_MODE=true" | Set-Content $targetFile
}

Write-Host "`n✨ Setup Complete!" -ForegroundColor Cyan
Write-Host "You can now run integration tests using:" -ForegroundColor White
Write-Host "flutter test --dart-define=SUPABASE_TEST_MODE=true --dart-define-from-file=.env.test" -ForegroundColor Yellow
