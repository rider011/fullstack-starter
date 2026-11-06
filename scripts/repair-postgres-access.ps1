param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectRoot
)

$ErrorActionPreference = 'Stop'
$backupRoot = Join-Path $env:USERPROFILE '.dev-env-backup\2026-11-06'
$logPath = Join-Path $backupRoot 'postgres-repair.log'
$statusPath = Join-Path $backupRoot 'postgres-repair.status'
$postgresRoot = 'C:\Program Files\PostgreSQL\18'
$postgresBin = Join-Path $postgresRoot 'bin'
$dataDir = Join-Path $postgresRoot 'data'
$hbaPath = Join-Path $dataDir 'pg_hba.conf'
$hbaBackup = Join-Path $backupRoot 'pg_hba.conf.before-repair'
$serviceName = 'postgresql-x64-18'
$temporaryRules = @(
    'host    all             postgres        127.0.0.1/32            trust',
    'host    all             postgres        ::1/128                 trust'
)

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
Start-Transcript -Path $logPath -Append | Out-Null

function New-AlphanumericSecret {
    param([int] $Length = 32)

    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $bytes = New-Object byte[] $Length
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
}

function Restart-PostgresService {
    $pgCtl = Join-Path $postgresBin 'pg_ctl.exe'
    & $pgCtl reload -D $dataDir
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to reload PostgreSQL configuration.'
    }
    Start-Sleep -Milliseconds 500
}

try {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'The PostgreSQL repair script must run as administrator.'
    }

    $service = Get-Service -Name $serviceName -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        Start-Service -Name $serviceName
        $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(30))
    }

    Copy-Item -LiteralPath $hbaPath -Destination $hbaBackup -Force
    $originalHba = Get-Content -Raw -LiteralPath $hbaPath
    $temporaryHba = (@($temporaryRules) + @($originalHba)) -join [Environment]::NewLine
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($hbaPath, $temporaryHba, $utf8WithoutBom)
    Restart-PostgresService

    $psql = Join-Path $postgresBin 'psql.exe'
    $createdb = Join-Path $postgresBin 'createdb.exe'
    $appPassword = New-AlphanumericSecret
    $roleSql = "DO `$`$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fullstack_dev') THEN CREATE ROLE fullstack_dev LOGIN CREATEDB PASSWORD '$appPassword'; ELSE ALTER ROLE fullstack_dev WITH LOGIN CREATEDB PASSWORD '$appPassword'; END IF; END `$`$;"
    & $psql -w -h localhost -p 5432 -U postgres -d postgres -v ON_ERROR_STOP=1 -c $roleSql
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to create or update the fullstack_dev database role.'
    }

    $databaseLookup = @(
        & $psql -w -h localhost -p 5432 -U postgres -d postgres -tAc `
            "SELECT 1 FROM pg_database WHERE datname = 'fullstack_dev';"
    )
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to inspect the application database.'
    }
    $databaseExists = ($databaseLookup -join '').Trim()
    if ($databaseExists -ne '1') {
        & $createdb -w -h localhost -p 5432 -U postgres -O fullstack_dev fullstack_dev
        if ($LASTEXITCODE -ne 0) {
            throw 'Failed to create the fullstack_dev database.'
        }
    }

    Copy-Item -LiteralPath $hbaBackup -Destination $hbaPath -Force
    Restart-PostgresService

    $envPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $pathParts = @($envPath -split ';' | Where-Object { $_ })
    if ($pathParts -notcontains $postgresBin) {
        [Environment]::SetEnvironmentVariable('Path', ((@($postgresBin) + $pathParts) -join ';'), 'User')
    }

    $apiEnvPath = Join-Path $ProjectRoot 'apps\api\.env'
    $databaseUrl = "postgresql://fullstack_dev:$appPassword@localhost:5432/fullstack_dev?schema=public"
    @(
        "DATABASE_URL=`"$databaseUrl`""
        'PORT=3000'
    ) | Set-Content -LiteralPath $apiEnvPath -Encoding utf8

    [pscustomobject]@{
        State = 'success'
        Message = 'Database role, database, authentication, PATH, and API environment repaired.'
        Timestamp = (Get-Date).ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding utf8
} catch {
    if (Test-Path -LiteralPath $hbaBackup) {
        Copy-Item -LiteralPath $hbaBackup -Destination $hbaPath -Force
        Restart-PostgresService
    }
    [pscustomobject]@{
        State = 'failed'
        Message = $_.Exception.Message
        Timestamp = (Get-Date).ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding utf8
    Write-Error $_
    exit 1
} finally {
    Stop-Transcript | Out-Null
}
