<#
.SYNOPSIS
    Script de automatización para inicializar Git y subir los 7 microservicios de ViajaMejor a GitHub.
.PARAMETER GithubUser
    Nombre de usuario de GitHub (obligatorio).
.EXAMPLE
    .\subir_repositorios.ps1 -GithubUser "miusuario"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$GithubUser
)

$msList = @("usuarios", "busqueda", "reservas", "pagos", "integraciones", "fidelizacion", "notificaciones")
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Automatizacion de Repositorios GitHub - ViajaMejor" -ForegroundColor Yellow
Write-Host "  Usuario GitHub: $GithubUser" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($ms in $msList) {
    $msPath = Join-Path $baseDir "ms\$ms"
    $repoName = "viajamejor-ms-$ms"
    $remoteUrl = "https://github.com/$GithubUser/$repoName.git"

    Write-Host "`n--> Procesando [$repoName] en $msPath..." -ForegroundColor Cyan

    if (Test-Path $msPath) {
        Push-Location $msPath
        
        # Eliminar .git previo si existe para inicio limpio
        if (Test-Path ".git") {
            Write-Host "  Reinicializando repositorio Git existente..." -ForegroundColor DarkGray
        }

        git init
        git branch -M main
        git add .
        git commit -m "feat: inicializacion de $repoName (Java 21, Spring Boot 3.3, JPA, OpenAPI, BDD Cucumber y Docker)"
        
        # Configurar remote
        git remote remove origin 2>$null
        git remote add origin $remoteUrl

        Write-Host "  Subiendo a $remoteUrl..." -ForegroundColor Green
        git push -u origin main --force

        Pop-Location
    } else {
        Write-Host "  [ALERTA] No se encontro la carpeta $msPath" -ForegroundColor Red
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Procesando repositorio de Arquitectura y Documentacion..." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

Push-Location $baseDir
git init
git branch -M main
git add .
git commit -m "docs: entrega EP01 ViajaMejor - diagramas C4, arquitectura AWS multi-AZ, justificacion y guion"
git remote remove origin 2>$null
git remote add origin "https://github.com/$GithubUser/viajamejor-arquitectura-entrega.git"
git push -u origin main --force
Pop-Location

Write-Host "`n[EXITO] Todos los repositorios fueron procesados exitosamente." -ForegroundColor Green
