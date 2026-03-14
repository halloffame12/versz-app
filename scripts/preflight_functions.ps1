param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

$functions = @(
  'send-notification',
  'gemini-summary',
  'update-trending',
  'update-leaderboard',
  'check-achievements',
  'update-xp',
  'calculate-winner',
  'anti-spam-check',
  'cast-vote'
)

$requiredGlobalEnv = @(
  'APPWRITE_ENDPOINT',
  'APPWRITE_PROJECT_ID',
  'APPWRITE_API_KEY',
  'DATABASE_ID'
)

$requiredPerFunctionEnv = @{
  'send-notification' = @('FIREBASE_SERVICE_JSON')
  'gemini-summary'    = @('GEMINI_API_KEY')
}

$issues = New-Object System.Collections.Generic.List[string]

function Add-Issue([string]$message) {
  $script:issues.Add($message)
}

Write-Host '== Versz Function Preflight ==' -ForegroundColor Cyan
Write-Host "Repo: $repoRoot"
Write-Host ''

foreach ($fn in $functions) {
  $fnRoot = Join-Path $repoRoot "functions/$fn"
  $pkg = Join-Path $fnRoot 'package.json'
  $entry = Join-Path $fnRoot 'src/index.js'

  Write-Host "[Check] $fn" -ForegroundColor Yellow

  if (-not (Test-Path $fnRoot)) {
    Add-Issue "Missing function folder: functions/$fn"
    Write-Host '  - folder: MISSING' -ForegroundColor Red
    continue
  }

  if (-not (Test-Path $pkg)) {
    Add-Issue "Missing package.json: functions/$fn/package.json"
    Write-Host '  - package.json: MISSING' -ForegroundColor Red
  } else {
    Write-Host '  - package.json: OK' -ForegroundColor Green
    try {
      $pkgJson = Get-Content $pkg -Raw | ConvertFrom-Json
      if ($pkgJson.main -ne 'src/index.js') {
        Add-Issue "Unexpected main in functions/$fn/package.json (expected src/index.js, found $($pkgJson.main))"
        Write-Host "  - main: $($pkgJson.main) (expected src/index.js)" -ForegroundColor Red
      } else {
        Write-Host '  - main: src/index.js' -ForegroundColor Green
      }
    } catch {
      Add-Issue "Invalid JSON in functions/$fn/package.json: $($_.Exception.Message)"
      Write-Host '  - package.json: INVALID JSON' -ForegroundColor Red
    }
  }

  if (-not (Test-Path $entry)) {
    Add-Issue "Missing entrypoint: functions/$fn/src/index.js"
    Write-Host '  - src/index.js: MISSING' -ForegroundColor Red
  } else {
    Write-Host '  - src/index.js: OK' -ForegroundColor Green
  }

  Write-Host ''
}

Write-Host '[Env] Global required vars' -ForegroundColor Yellow
foreach ($name in $requiredGlobalEnv) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    Add-Issue "Missing env var: $name"
    Write-Host "  - ${name}: MISSING" -ForegroundColor Red
  } else {
    Write-Host "  - ${name}: SET" -ForegroundColor Green
  }
}

Write-Host ''
Write-Host '[Env] Function-specific vars' -ForegroundColor Yellow
foreach ($fn in $requiredPerFunctionEnv.Keys) {
  Write-Host "  $fn"
  foreach ($name in $requiredPerFunctionEnv[$fn]) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
      Add-Issue "Missing env var for ${fn}: ${name}"
      Write-Host "    - ${name}: MISSING" -ForegroundColor Red
    } else {
      Write-Host "    - ${name}: SET" -ForegroundColor Green
    }
  }
}

Write-Host ''
if ($issues.Count -eq 0) {
  Write-Host 'Preflight PASSED: deployment prerequisites look good.' -ForegroundColor Green
  exit 0
}

Write-Host 'Preflight FOUND ISSUES:' -ForegroundColor Red
$issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }

if ($Strict) {
  exit 2
}

exit 0
