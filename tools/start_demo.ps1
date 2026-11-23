$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))

function New-LocalSecret([int] $byteCount) {
    $bytes = [byte[]]::new($byteCount)
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace('-', '')
}

if (-not (Test-Path -LiteralPath '.env.demo')) {
    $values = @(
        "FLEETOPS_TEST_SA_PASSWORD=DemoSql!$(New-LocalSecret 16)"
        "FLEETOPS_DEMO_RUNTIME_PASSWORD=DemoRun!$(New-LocalSecret 16)"
        "FLEETOPS_DEMO_PASSWORD=$(New-LocalSecret 16)"
        "FLEETOPS_DEMO_SESSION_SECRET=$(New-LocalSecret 32)"
    )
    [System.IO.File]::WriteAllLines((Join-Path (Get-Location) '.env.demo'), $values)
    Write-Host 'Created ignored .env.demo with local-only credentials.'
}

docker compose --env-file .env.demo -f compose.demo.yaml up -d --build --wait web
if ($LASTEXITCODE -ne 0) { throw 'FleetOps demo did not start. Inspect docker compose logs.' }
Write-Host 'FleetOps demo: http://localhost:18080'
Write-Host 'Accounts: demo_creator and demo_reader. Find the local password in .env.demo.'
