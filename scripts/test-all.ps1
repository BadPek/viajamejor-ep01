# Ejecuta mvn clean verify (pruebas + JaCoCo 100%) en los 7 microservicios y tests serverless.
$ErrorActionPreference = "Stop"
$services = @("usuarios", "busqueda", "reservas", "pagos", "integraciones", "fidelizacion", "notificaciones")
$baseDir = Split-Path -Parent $PSScriptRoot

if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME\bin")) {
    if (Test-Path "C:\Program Files\Java\jdk-22") {
        $env:JAVA_HOME = "C:\Program Files\Java\jdk-22"
    }
}
if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin")) {
    $env:Path = "$env:JAVA_HOME\bin;C:\Program Files\Apache NetBeans\java\maven\bin;" + $env:Path
} else {
    $env:Path = "C:\Program Files\Apache NetBeans\java\maven\bin;" + $env:Path
}

foreach ($s in $services) {
    Write-Host "== Verificando ms/$s (mvn clean verify) ==" -ForegroundColor Cyan
    Push-Location (Join-Path $baseDir "ms\$s")
    mvn -B clean verify
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALLO en ms/$s" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}

Write-Host "== Verificando funcion serverless (voucher-generator) ==" -ForegroundColor Cyan
Push-Location $baseDir
python -m unittest discover -s serverless/voucher-generator -v
if ($LASTEXITCODE -ne 0) {
    Write-Host "FALLO en serverless/voucher-generator" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "OK: 7 microservicios (JaCoCo 100%) y funcion serverless verificados con exito." -ForegroundColor Green
