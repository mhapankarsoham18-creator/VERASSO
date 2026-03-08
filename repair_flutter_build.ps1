Write-Host "Cleaning Flutter project..." -ForegroundColor Cyan

flutter clean

Write-Host "Removing Gradle cache..." -ForegroundColor Cyan
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\build -ErrorAction SilentlyContinue

Write-Host "Repairing packages..." -ForegroundColor Cyan
flutter pub get

Write-Host "Repairing platform files..." -ForegroundColor Cyan
flutter create .

Write-Host "Building APK..." -ForegroundColor Cyan
flutter build apk --debug

Write-Host "Repair complete!" -ForegroundColor Green
