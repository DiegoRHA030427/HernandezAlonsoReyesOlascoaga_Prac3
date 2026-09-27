# ---------------------------------------------------------------------------
# Practica 3 - Ejercicio 4 (Flutter)
# Genera las carpetas android/ e ios/ con TU version de Flutter y aplica los
# ajustes del proyecto. Se ejecuta UNA sola vez, desde esta carpeta:
#
#   powershell -ExecutionPolicy Bypass -File .\configurar_plataformas.ps1
#
# "flutter create ." no sobrescribe lib/, test/, pubspec.yaml ni README.md:
# solo crea los archivos que faltan.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host '==> Generando plataformas android e ios...'
flutter create --org mx.ipn.escom --project-name gestor_archivos --platforms=android,ios .
if ($LASTEXITCODE -ne 0) { throw 'flutter create fallo' }

function Update-TextFile($path, [scriptblock]$transform) {
    if (-not (Test-Path $path)) { Write-Warning "No existe $path"; return }
    $text = [IO.File]::ReadAllText((Resolve-Path $path))
    $new = & $transform $text
    [IO.File]::WriteAllText((Resolve-Path $path), $new, (New-Object Text.UTF8Encoding($false)))
}

Write-Host '==> Android: nombre visible de la app'
Update-TextFile 'android\app\src\main\AndroidManifest.xml' {
    param($t) $t -replace 'android:label="[^"]*"', 'android:label="Gestor de Archivos"'
}

Write-Host '==> iOS: nombre visible y carpeta Documents visible en la app Archivos'
Update-TextFile 'ios\Runner\Info.plist' {
    param($t)
    $t = $t -replace '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', '${1}Gestor de Archivos${2}'
    if ($t -notmatch 'UIFileSharingEnabled') {
        $extra = "`t<key>UIFileSharingEnabled</key>`n`t<true/>`n`t<key>LSSupportsOpeningDocumentsInPlace</key>`n`t<true/>`n"
        $t = $t -replace '</dict>\s*</plist>\s*$', ($extra + "</dict>`n</plist>`n")
    }
    $t
}

Write-Host '==> Descargando dependencias (solo esta vez se necesita internet)'
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get fallo' }

Write-Host ''
Write-Host 'Listo. Ahora puedes correr:  flutter run'
