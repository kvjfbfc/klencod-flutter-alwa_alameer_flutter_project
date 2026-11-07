$ErrorActionPreference = 'Stop'
$ProjectName = 'alwa_alameer'
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host 'Flutter غير موجود في PATH. ثبّت Flutter ثم أعد فتح PowerShell.' -ForegroundColor Red
  exit 1
}

if (Test-Path $ProjectName) {
  Write-Host "المجلد $ProjectName موجود مسبقاً. غيّر اسمه أو احذفه قبل المتابعة." -ForegroundColor Yellow
  exit 1
}

flutter create --org com.alameer.inventory --project-name $ProjectName $ProjectName
Copy-Item "$SourceDir\lib" "$ProjectName\lib" -Recurse -Force
Copy-Item "$SourceDir\pubspec.yaml" "$ProjectName\pubspec.yaml" -Force

$Manifest = "$ProjectName\android\app\src\main\AndroidManifest.xml"
$Xml = Get-Content $Manifest -Raw
if ($Xml -notmatch 'android.permission.INTERNET') {
  $Xml = $Xml -replace '(<manifest[^>]*>)', ('$1' + "`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />")
}
$Xml = $Xml -replace 'android:label="[^"]*"', 'android:label="علوة الأمير"'
Set-Content -Path $Manifest -Value $Xml -Encoding UTF8

Push-Location $ProjectName
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'فشل تنزيل مكتبات Flutter.' }
Write-Host ''
Write-Host 'تم إنشاء المشروع. لاستخراج APK نفّذ:' -ForegroundColor Green
Write-Host 'flutter build apk --release' -ForegroundColor Cyan
Write-Host 'مسار APK: build\app\outputs\flutter-apk\app-release.apk'
Pop-Location
