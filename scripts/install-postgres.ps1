param(
    [Parameter(Mandatory = $true)]
    [string] $InstallerPath,

    [Parameter(Mandatory = $true)]
    [string] $ProjectRoot
)

$ErrorActionPreference = 'Stop'
$backupRoot = Join-Path $env:USERPROFILE '.dev-env-backup\2026-11-06'
$logPath = Join-Path $backupRoot 'postgres-install.log'
$statusPath = Join-Path $backupRoot 'postgres-install.status'
$postgresRoot = 'C:\Program Files\PostgreSQL\18'
$postgresBin = Join-Path $postgresRoot 'bin'
$serviceName = 'postgresql-x64-18'

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
Start-Transcript -Path $logPath -Append | Out-Null

function New-AlphanumericSecret {
    param([int] $Length = 32)

    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $bytes = New-Object byte[] $Length
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
}

function Set-InstallStatus {
    param(
        [string] $State,
        [string] $Message
    )

    [pscustomobject]@{
        State = $State
        Message = $Message
        Timestamp = (Get-Date).ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding utf8
}

try {
    $principal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'The PostgreSQL setup script must run as administrator.'
    }

    $shimPath = 'C:\Windows\system32\winget'
    if (Test-Path -LiteralPath $shimPath) {
        $shim = Get-Item -LiteralPath $shimPath
        if ($shim.Length -ne 0) {
            throw "Refusing to remove non-empty file: $shimPath"
        }

        $shimBackup = Join-Path $backupRoot 'system32-winget.empty'
        Move-Item -LiteralPath $shimPath -Destination $shimBackup -Force
    }

    $expectedHash = '227e2bc08091b4c2b8338c7d61b11d057f895711480b006f90bfcfcd2410a58a'
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $InstallerPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "PostgreSQL installer hash mismatch: $actualHash"
    }

    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if (-not $existingService) {
        $superPassword = New-AlphanumericSecret
        $installerStdout = Join-Path $backupRoot 'postgres-installer.stdout.log'
        $installerStderr = Join-Path $backupRoot 'postgres-installer.stderr.log'
        $installerTrace = Join-Path $backupRoot 'postgres-installer.trace.log'
        $installerArguments = @(
            '--mode', 'unattended',
            '--unattendedmodeui', 'none',
            '--superpassword', $superPassword,
            '--servicename', $serviceName,
            '--serverport', '5432',
            '--prefix', "`"$postgresRoot`"",
            '--install_runtimes', '0',
            '--debuglevel', '4',
            '--debugtrace', "`"$installerTrace`""
        )

        Write-Host "Installing PostgreSQL 18 to $postgresRoot"
        $installer = Start-Process -FilePath $InstallerPath -ArgumentList $installerArguments `
            -Wait -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput $installerStdout -RedirectStandardError $installerStderr
        if ($installer.ExitCode -ne 0) {
            throw "PostgreSQL installer exited with code $($installer.ExitCode)."
        }
    } else {
        throw "PostgreSQL service already exists but this setup cannot recover its superuser password. Refusing to overwrite it."
    }

    $psql = Join-Path $postgresBin 'psql.exe'
    $createdb = Join-Path $postgresBin 'createdb.exe'
    if (-not (Test-Path -LiteralPath $psql)) {
        throw "psql.exe was not found at $psql"
    }

    $env:PGPASSWORD = $superPassword
    $appPassword = New-AlphanumericSecret
    $roleSql = "DO `$`$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fullstack_dev') THEN CREATE ROLE fullstack_dev LOGIN CREATEDB PASSWORD '$appPassword'; ELSE ALTER ROLE fullstack_dev WITH LOGIN CREATEDB PASSWORD '$appPassword'; END IF; END `$`$;"
    & $psql -h localhost -p 5432 -U postgres -d postgres -v ON_ERROR_STOP=1 -c $roleSql
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create or update the fullstack_dev database role."
    }

    $databaseLookup = @(
        & $psql -h localhost -p 5432 -U postgres -d postgres -tAc `
            "SELECT 1 FROM pg_database WHERE datname = 'fullstack_dev';"
    )
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to inspect the fullstack_dev database."
    }
    $databaseExists = ($databaseLookup -join '').Trim()
    if ($databaseExists -ne '1') {
        & $createdb -h localhost -p 5432 -U postgres -O fullstack_dev fullstack_dev
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create the fullstack_dev database."
        }
    }

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

    Set-InstallStatus -State 'success' -Message 'PostgreSQL 18 installed; app role, database, PATH, and API environment configured.'
    Write-Host 'PostgreSQL setup completed successfully.'
} catch {
    Set-InstallStatus -State 'failed' -Message $_.Exception.Message
    Write-Error $_
    exit 1
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Stop-Transcript | Out-Null
}
