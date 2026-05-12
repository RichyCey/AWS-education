$ErrorActionPreference = "Stop"

$layerDir = Join-Path $PSScriptRoot "layer"
$zipPath = Join-Path $PSScriptRoot "psycopg2_layer.zip"

if (Test-Path $layerDir) { Remove-Item -Recurse -Force $layerDir }
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

New-Item -ItemType Directory -Force -Path $layerDir | Out-Null

Write-Host "Building psycopg2 layer for Python 3.13 using Docker..."

docker run --rm -v "${layerDir}:/layer" python:3.13-slim `
    bash -c "pip install psycopg2-binary -t /layer/python && find /layer -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed. Ensure Docker is installed and running."
    exit 1
}

Compress-Archive -Path "$layerDir\python" -DestinationPath $zipPath -Force

Write-Host "Layer built successfully: $zipPath"
Write-Host "You can now run: terraform apply -var deploy_lambda=true"
