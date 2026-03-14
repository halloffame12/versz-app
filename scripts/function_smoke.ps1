$ErrorActionPreference = 'Stop'

$endpoint = $env:APPWRITE_ENDPOINT
$project = $env:APPWRITE_PROJECT_ID
$apiKey = $env:APPWRITE_API_KEY

if ([string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($project) -or [string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing APPWRITE_ENDPOINT / APPWRITE_PROJECT_ID / APPWRITE_API_KEY.'
}

$headers = @{
  'X-Appwrite-Project' = $project
  'X-Appwrite-Key' = $apiKey
  'Content-Type' = 'application/json'
}

$cases = @(
  @{ name='anti-spam-check';  body='{"userId":"smoke-user","action":"vote_cast"}'; expect='allow-or-validation' },
  @{ name='cast-vote';        body='{"userId":"smoke-user","debateId":"smoke-debate","side":"agree"}'; expect='validation-or-not-found' },
  @{ name='update-xp';        body='{"userId":"smoke-user","action":"vote_cast","referenceId":"smoke-debate"}'; expect='validation-or-not-found' },
  @{ name='calculate-winner'; body='{"debateId":"smoke-debate"}'; expect='validation-or-not-found' },
  @{ name='check-achievements'; body='{"userId":"smoke-user"}'; expect='validation-or-not-found' },
  @{ name='gemini-summary';   body='{}'; expect='validation-or-config' },
  @{ name='send-notification'; body='{"userId":"smoke-user","title":"Smoke","body":"Test","type":"system"}'; expect='validation-or-provider' },
  @{ name='update-trending';  body='{}'; expect='scheduled-manual-ok' },
  @{ name='update-leaderboard'; body='{}'; expect='scheduled-manual-ok' }
)

function Get-FunctionsMap {
  $resp = Invoke-RestMethod -Method Get -Uri "$endpoint/functions?limit=200" -Headers @{ 'X-Appwrite-Project' = $project; 'X-Appwrite-Key' = $apiKey }
  $map = @{}
  foreach ($f in $resp.functions) {
    $map[$f.name] = $f.'$id'
  }
  return $map
}

function Start-Execution([string]$functionId, [string]$body) {
  $payload = @{ body = $body; async = $false } | ConvertTo-Json -Compress
  return Invoke-RestMethod -Method Post -Uri "$endpoint/functions/$functionId/executions" -Headers $headers -Body $payload
}

function Poll-Execution([string]$functionId, [string]$executionId, [int]$maxSeconds = 45) {
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  do {
    Start-Sleep -Milliseconds 800
    $e = Invoke-RestMethod -Method Get -Uri "$endpoint/functions/$functionId/executions/$executionId" -Headers @{ 'X-Appwrite-Project' = $project; 'X-Appwrite-Key' = $apiKey }
    if ($e.status -in @('completed', 'failed')) {
      return $e
    }
  } while ($stopwatch.Elapsed.TotalSeconds -lt $maxSeconds)

  return $e
}

$map = Get-FunctionsMap
$results = @()

Write-Host '== Function Smoke Test ==' -ForegroundColor Cyan

foreach ($c in $cases) {
  $name = $c.name
  if (-not $map.ContainsKey($name)) {
    $results += [pscustomobject]@{
      Function = $name
      Status = 'RED'
      ExecStatus = 'missing'
      Http = ''
      Note = 'Function not found'
    }
    continue
  }

  $id = $map[$name]
  try {
    $started = Start-Execution -functionId $id -body $c.body
    $execId = $started.'$id'
    $done = Poll-Execution -functionId $id -executionId $execId

    $httpCode = ''
    if ($null -ne $done.responseStatusCode) { $httpCode = [string]$done.responseStatusCode }

    $ok = $done.status -eq 'completed'
    $color = if ($ok) { 'GREEN' } else { 'RED' }

    $note = ''
    if ($ok) {
      if ($httpCode -match '^(2|4)\d\d$') {
        $note = 'Runnable (2xx/4xx acceptable for smoke payload)'
      } else {
        $note = 'Completed but non-2xx/4xx response'
      }
    } else {
      $note = 'Execution failed'
    }

    $results += [pscustomobject]@{
      Function = $name
      Status = $color
      ExecStatus = $done.status
      Http = $httpCode
      Note = $note
    }
  } catch {
    $msg = $_.Exception.Message
    if ($_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
    $results += [pscustomobject]@{
      Function = $name
      Status = 'RED'
      ExecStatus = 'request-error'
      Http = ''
      Note = $msg
    }
  }
}

$results | Sort-Object Function | Format-Table -AutoSize

$reds = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($reds -gt 0) {
  Write-Host "Smoke result: $reds RED" -ForegroundColor Red
  exit 2
}

Write-Host 'Smoke result: all GREEN' -ForegroundColor Green
exit 0
