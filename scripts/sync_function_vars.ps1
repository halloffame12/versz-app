param(
  [string]$DatabaseId = 'versz-db'
)

$ErrorActionPreference = 'Stop'

$endpoint = $env:APPWRITE_ENDPOINT
$project = $env:APPWRITE_PROJECT_ID
$apiKey = $env:APPWRITE_API_KEY
$firebaseJson = $env:FIREBASE_SERVICE_JSON
$geminiKey = $env:GEMINI_API_KEY

if ([string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($project) -or [string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing APPWRITE_ENDPOINT / APPWRITE_PROJECT_ID / APPWRITE_API_KEY in environment.'
}

$headers = @{
  'X-Appwrite-Project' = $project
  'X-Appwrite-Key' = $apiKey
  'Content-Type' = 'application/json'
}

$targetFunctionNames = @(
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

function Invoke-AppwriteJson($method, $uri, $bodyObj) {
  if ($null -eq $bodyObj) {
    return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers
  }
  $json = $bodyObj | ConvertTo-Json -Compress -Depth 10
  return Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body $json
}

function Upsert-Variable($functionId, $key, $value) {
  if ([string]::IsNullOrWhiteSpace($value)) {
    Write-Host "  - $key skipped (empty)" -ForegroundColor Yellow
    return
  }

  $varsUri = "$endpoint/functions/$functionId/variables"
  $existing = Invoke-AppwriteJson 'GET' $varsUri $null
  $hit = $existing.variables | Where-Object { $_.key -eq $key } | Select-Object -First 1

  if ($null -ne $hit) {
    $patchUri = "$endpoint/functions/$functionId/variables/$($hit.'$id')"
    Invoke-AppwriteJson 'PUT' $patchUri @{ key = $key; value = $value } | Out-Null
    Write-Host "  - $key updated" -ForegroundColor Green
  } else {
    Invoke-AppwriteJson 'POST' $varsUri @{ key = $key; value = $value } | Out-Null
    Write-Host "  - $key created" -ForegroundColor Green
  }
}

Write-Host '== Sync Appwrite Function Variables ==' -ForegroundColor Cyan
Write-Host "Endpoint: $endpoint"
Write-Host "Project: $project"
Write-Host ''

$functionsResp = Invoke-AppwriteJson 'GET' "$endpoint/functions?limit=200" $null
$functions = @($functionsResp.functions)

$resolved = @{}
foreach ($name in $targetFunctionNames) {
  $f = $functions | Where-Object { $_.name -eq $name -or $_.'$id' -eq $name } | Select-Object -First 1
  if ($null -eq $f) {
    Write-Host "[Missing] Function not found: $name" -ForegroundColor Red
    continue
  }
  $resolved[$name] = $f.'$id'
}

foreach ($name in $resolved.Keys) {
  $fid = $resolved[$name]
  Write-Host "[Function] $name ($fid)" -ForegroundColor Yellow

  Upsert-Variable $fid 'APPWRITE_ENDPOINT' $endpoint
  Upsert-Variable $fid 'APPWRITE_PROJECT_ID' $project
  Upsert-Variable $fid 'APPWRITE_API_KEY' $apiKey
  Upsert-Variable $fid 'DATABASE_ID' $DatabaseId

  if ($name -eq 'send-notification') {
    Upsert-Variable $fid 'FIREBASE_SERVICE_JSON' $firebaseJson
  }

  if ($name -eq 'gemini-summary') {
    Upsert-Variable $fid 'GEMINI_API_KEY' $geminiKey
  }

  Write-Host ''
}

if ([string]::IsNullOrWhiteSpace($geminiKey)) {
  Write-Host 'WARNING: GEMINI_API_KEY was empty; gemini-summary variable was not set.' -ForegroundColor Yellow
}

Write-Host 'Variable sync complete.' -ForegroundColor Cyan
