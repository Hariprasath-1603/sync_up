# Supabase Edge Functions Deployment Script
# Run this script to deploy both send-otp and verify-otp functions

Write-Host "🚀 Deploying Supabase Edge Functions..." -ForegroundColor Cyan

# Check if supabase CLI is installed
try {
    supabase --version
} catch {
    Write-Host "❌ Supabase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g supabase" -ForegroundColor Yellow
    exit 1
}

# Make sure we're in the project directory
Set-Location -Path $PSScriptRoot

Write-Host "`n📦 Deploying send-otp function..." -ForegroundColor Yellow
supabase functions deploy send-otp --project-ref cgkexriarshbftnjftlm

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ send-otp deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ send-otp deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Deploying verify-otp function..." -ForegroundColor Yellow
supabase functions deploy verify-otp --project-ref cgkexriarshbftnjftlm

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ verify-otp deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ verify-otp deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 All functions deployed successfully!" -ForegroundColor Green
Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Set Twilio secrets (if not already set):" -ForegroundColor White
Write-Host "   supabase secrets set TWILIO_ACCOUNT_SID=ACxxx..." -ForegroundColor Gray
Write-Host "   supabase secrets set TWILIO_AUTH_TOKEN=your_token" -ForegroundColor Gray
Write-Host "   supabase secrets set TWILIO_VERIFY_SERVICE_SID=VAxxx..." -ForegroundColor Gray
Write-Host "`n2. View functions in dashboard:" -ForegroundColor White
Write-Host "   https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/functions" -ForegroundColor Gray
Write-Host "`n3. Test the functions from your Flutter app!" -ForegroundColor White
