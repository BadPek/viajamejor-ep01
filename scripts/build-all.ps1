# Compila y empaqueta los 7 microservicios de ViajaMejor (genera el .jar ejecutable en target/)
$ErrorActionPreference = "Stop"
$services = @("usuarios", "busqueda", "reservas", "pagos", "integraciones", "fidelizacion", "notificaciones")
$baseDir = Split-Path -Parent $PSScriptRoot

if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin")) {
    $env:Path = "$env:JAVA_HOME\bin;C:\Program Files\Apache NetBeans\java\maven\bin;" + $env:Path
} else {
    $env:Path = "C:\Program Files\Apache NetBeans\java\maven\bin;" + $env:Path
}

foreach ($s in $services) {
    Write-Host "== Empaquetando ms/$s ==" -ForegroundColor Cyan
    Push-Location (Join-Path $baseDir "ms\$s")
    mvn -q clean package -DskipTests
    Pop-Location
}
Write-Host "OK: artefactos generados en ms/<servicio>/target/*.jar" -ForegroundColor Green
