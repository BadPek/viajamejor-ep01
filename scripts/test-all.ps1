# Ejecuta pruebas y valida cobertura JaCoCo en los 7 microservicios.
$ErrorActionPreference = "Stop"
$services = @("usuarios", "busqueda", "reservas", "pagos", "integraciones", "fidelizacion", "notificaciones")
$baseDir = Split-Path -Parent $PSScriptRoot

if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME\bin")) {
    $env:JAVA_HOME = "C:\Program Files\Java\jdk-22"
}
$env:Path = "$env:JAVA_HOME\bin;C:\Program Files\Apache NetBeans\java\maven\bin;" + $env:Path

foreach ($s in $services) {
    Write-Host "== Probando ms/$s ==" -ForegroundColor Cyan
    Push-Location (Join-Path $baseDir "ms\$s")
    mvn test
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALLO en ms/$s" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
}
Write-Host "OK: pruebas unitarias, MockMvc, Cucumber y JaCoCo completadas con exito." -ForegroundColor Green
