$ErrorActionPreference = 'Stop'

$endpoint = $env:APPWRITE_ENDPOINT
$project = $env:APPWRITE_PROJECT_ID
$apiKey = $env:APPWRITE_API_KEY
$db = if ([string]::IsNullOrWhiteSpace($env:DATABASE_ID)) { 'versz-db' } else { $env:DATABASE_ID }

if ([string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($project) -or [string]::IsNullOrWhiteSpace($apiKey)) {
  throw 'Missing APPWRITE_ENDPOINT / APPWRITE_PROJECT_ID / APPWRITE_API_KEY.'
}

$headers = @{
  'X-Appwrite-Project' = $project
  'X-Appwrite-Key' = $apiKey
  'Content-Type' = 'application/json'
}

$readHeaders = @{
  'X-Appwrite-Project' = $project
  'X-Appwrite-Key' = $apiKey
}

function Get-FunctionsMap {
  $resp = Invoke-RestMethod -Method Get -Uri "$endpoint/functions?limit=200" -Headers $readHeaders
  $map = @{}
  foreach ($f in $resp.functions) {
    $map[$f.name] = $f.'$id'
  }
  return $map
}

function Get-SampleIds {
  $out = [ordered]@{ UserId = $null; DebateId = $null }

  try {
    $users = Invoke-RestMethod -Method Get -Uri "$endpoint/databases/$db/collections/users/documents?limit=1" -Headers $readHeaders
    if ($users.documents.Count -gt 0) { $out.UserId = $users.documents[0].'$id' }
  } catch {}

  try {
    $debates = Invoke-RestMethod -Method Get -Uri "$endpoint/databases/$db/collections/debates/documents?limit=1" -Headers $readHeaders
    if ($debates.documents.Count -gt 0) { $out.DebateId = $debates.documents[0].'$id' }
  } catch {}

  return $out
}

function Create-SmokeDebate([string]$userId) {
  if ([string]::IsNullOrWhiteSpace($userId)) { return $null }

  $payload = @{
    documentId = 'unique()'
    data = @{
      topic = 'Function Smoke Debate'
      description = 'Auto-created for function smoke validation'
      category = 'general'
      creatorId = $userId
      creatorName = 'smoke-user'
      agreeCount = 0
      disagreeCount = 0
      upvotes = 0
      downvotes = 0
      likeCount = 0
      commentCount = 0
      viewCount = 0
      status = 'active'
      isTrending = $false
      trendingScore = 0.0
      hashtags = ''
      createdAt = (Get-Date).ToString('o')
      updatedAt = (Get-Date).ToString('o')
    }
  } | ConvertTo-Json -Depth 10 -Compress

  try {
    $doc = Invoke-RestMethod -Method Post -Uri "$endpoint/databases/$db/collections/debates/documents" -Headers $headers -Body $payload
    return $doc.'$id'
  } catch {
    return $null
  }
}

function Start-Execution([string]$functionId, [string]$body) {
  $payload = @{ body = $body; async = $false } | ConvertTo-Json -Compress
  return Invoke-RestMethod -Method Post -Uri "$endpoint/functions/$functionId/executions" -Headers $headers -Body $payload
}

function Poll-Execution([string]$functionId, [string]$executionId, [int]$maxSeconds = 45) {
  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  do {
    Start-Sleep -Milliseconds 800
    $e = Invoke-RestMethod -Method Get -Uri "$endpoint/functions/$functionId/executions/$executionId" -Headers $readHeaders
    if ($e.status -in @('completed', 'failed')) {
      return $e
    }
  } while ($stopwatch.Elapsed.TotalSeconds -lt $maxSeconds)

  return $e
}

Write-Host '== Function Smoke Test ==' -ForegroundColor Cyan

$ids = Get-SampleIds
if ([string]::IsNullOrWhiteSpace($ids.UserId)) {
  throw 'No user found in users collection; cannot run smoke.'
}
if ([string]::IsNullOrWhiteSpace($ids.DebateId)) {
  $ids.DebateId = Create-SmokeDebate -userId $ids.UserId
}

Write-Host "Using userId=$($ids.UserId)"
Write-Host "Using debateId=$($ids.DebateId)"

$cases = @(
  @{ name='anti-spam-check'; body=(@{ userId=$ids.UserId; action='vote_cast' } | ConvertTo-Json -Compress) },
  @{ name='cast-vote'; body=(@{ userId=$ids.UserId; debateId=$ids.DebateId; side='agree' } | ConvertTo-Json -Compress) },
  @{ name='update-xp'; body=(@{ userId=$ids.UserId; action='vote_cast'; referenceId=$ids.DebateId } | ConvertTo-Json -Compress) },
  @{ name='calculate-winner'; body=(@{ debateId=$ids.DebateId } | ConvertTo-Json -Compress) },
  @{ name='check-achievements'; body=(@{ userId=$ids.UserId } | ConvertTo-Json -Compress) },
  @{ name='gemini-summary'; body='{}' },
  @{ name='send-notification'; body=(@{ userId=$ids.UserId; title='Smoke'; body='Function test'; type='system' } | ConvertTo-Json -Compress) },
  @{ name='update-trending'; body='{}' },
  @{ name='update-leaderboard'; body='{}' }
)

$map = Get-FunctionsMap
$results = @()

foreach ($c in $cases) {
  $name = $c.name
  if (-not $map.ContainsKey($name)) {
    $results += [pscustomobject]@{ Function=$name; Status='RED'; ExecStatus='missing'; Http=''; Note='Function not found' }
    continue
  }

  if (($name -in @('cast-vote','calculate-winner')) -and [string]::IsNullOrWhiteSpace($ids.DebateId)) {
    $results += [pscustomobject]@{ Function=$name; Status='SKIP'; ExecStatus='skipped'; Http=''; Note='No debate available' }
    continue
  }

  try {
    $started = Start-Execution -functionId $map[$name] -body $c.body
    $done = Poll-Execution -functionId $map[$name] -executionId $started.'$id'

    $httpCode = if ($null -ne $done.responseStatusCode) { [string]$done.responseStatusCode } else { '' }
    $isGreen = $done.status -eq 'completed'

    $note = if ($isGreen) {
      if ($httpCode -match '^(2|4)\d\d$') { 'Runnable (2xx/4xx acceptable for smoke payload)' }
      else { 'Completed with non-2xx/4xx response' }
    } else {
      'Execution failed'
    }

    $results += [pscustomobject]@{
      Function = $name
      Status = if ($isGreen) { 'GREEN' } else { 'RED' }
      ExecStatus = $done.status
      Http = $httpCode
      Note = $note
    }
  } catch {
    $msg = $_.Exception.Message
    if ($_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
    $results += [pscustomobject]@{ Function=$name; Status='RED'; ExecStatus='request-error'; Http=''; Note=$msg }
  }
}

$results | Sort-Object Function | Format-Table -AutoSize

$reds = @($results | Where-Object { $_.Status -eq 'RED' }).Count
if ($reds -gt 0) {
  Write-Host "Smoke result: $reds RED" -ForegroundColor Red
  exit 2
}

Write-Host 'Smoke result: all GREEN/SKIP' -ForegroundColor Green
exit 0
