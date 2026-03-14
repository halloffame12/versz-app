$ErrorActionPreference = 'Stop'

$endpoint = $env:APPWRITE_ENDPOINT
$project = $env:APPWRITE_PROJECT_ID
$apiKey = $env:APPWRITE_API_KEY

if ([string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($project) -or [string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing APPWRITE_ENDPOINT / APPWRITE_PROJECT_ID / APPWRITE_API_KEY in environment.'
}

$headers = @{
  'X-Appwrite-Project' = $project
  'X-Appwrite-Key' = $apiKey
  'Content-Type' = 'application/json'
}

$required = @(
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

function Invoke-Appwrite([string]$method, [string]$uri, $bodyObj = $null) {
  if ($null -eq $bodyObj) {
    return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers
  }
  $json = $bodyObj | ConvertTo-Json -Depth 10 -Compress
  return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body $json
}

Write-Host '== Deploy Missing Functions ==' -ForegroundColor Cyan
$all = Invoke-Appwrite 'GET' "$endpoint/functions?limit=200"
$existing = @($all.functions)
$existingNames = $existing | ForEach-Object { $_.name }

$missing = $required | Where-Object { $_ -notin $existingNames }
if ($missing.Count -eq 0) {
  Write-Host 'No missing functions. All required function IDs are present.' -ForegroundColor Green
  exit 0
}

$template = $existing | Where-Object { $_.name -eq 'update-trending' } | Select-Object -First 1
if ($null -eq $template) {
  throw 'Cannot find template function update-trending; aborting.'
}

foreach ($name in $missing) {
  Write-Host "[Create] $name" -ForegroundColor Yellow

  $schedule = ''
  if ($name -eq 'update-trending') { $schedule = '*/5 * * * *' }
  if ($name -eq 'update-leaderboard') { $schedule = '* * * * *' }

  $createBody = @{
    functionId = 'unique()'
    name = $name
    runtime = $template.runtime
    execute = @()
    events = @()
    schedule = $schedule
    timeout = [int]$template.timeout
    enabled = $true
    logging = $true
    entrypoint = 'src/index.js'
    commands = 'npm install'
    installationId = $template.installationId
    providerRepositoryId = $template.providerRepositoryId
    providerBranch = $template.providerBranch
    providerRootDirectory = "/functions/$name"
    providerSilentMode = $template.providerSilentMode
  }

  $created = Invoke-Appwrite 'POST' "$endpoint/functions" $createBody
  $functionId = $created.'$id'
  Write-Host "  created id: $functionId" -ForegroundColor Green

  try {
    $depBody = @{ activate = $true }
    $deployment = Invoke-Appwrite 'POST' "$endpoint/functions/$functionId/deployments" $depBody
    Write-Host "  deployment triggered: $($deployment.'$id')" -ForegroundColor Green
  } catch {
    Write-Host "  deployment trigger failed: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.ErrorDetails.Message) {
      Write-Host "  details: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
  }
}

Write-Host 'Function creation flow complete.' -ForegroundColor Cyan
