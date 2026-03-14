$ErrorActionPreference = 'Stop'

$endpoint = $env:APPWRITE_ENDPOINT
$project = $env:APPWRITE_PROJECT_ID
$key = $env:APPWRITE_API_KEY

$h = @{ 'X-Appwrite-Project' = $project; 'X-Appwrite-Key' = $key; 'Content-Type' = 'application/json' }
$rh = @{ 'X-Appwrite-Project' = $project; 'X-Appwrite-Key' = $key }

$f = Invoke-RestMethod -Method Get -Uri "$endpoint/functions?limit=200" -Headers $rh
$map = @{}
foreach ($x in $f.functions) { $map[$x.name] = $x.'$id' }

$cases = @(
  @{ name = 'update-leaderboard'; body = '{}' },
  @{ name = 'send-notification'; body = '{"userId":"69b426311b43b6fb81dd","title":"Smoke","body":"test","type":"system"}' },
  @{ name = 'cast-vote'; body = '{"userId":"69b426311b43b6fb81dd","debateId":"smoke-debate","side":"agree"}' },
  @{ name = 'calculate-winner'; body = '{"debateId":"smoke-debate"}' }
)

foreach ($c in $cases) {
  try {
    $id = $map[$c.name]
    if (-not $id) {
      Write-Output "$($c.name): MISSING"
      continue
    }

    $start = Invoke-RestMethod -Method Post -Uri "$endpoint/functions/$id/executions" -Headers $h -Body (@{ body = $c.body; async = $false } | ConvertTo-Json -Compress)
    $eid = $start.'$id'

    Start-Sleep -Milliseconds 1200
    $exec = Invoke-RestMethod -Method Get -Uri "$endpoint/functions/$id/executions/$eid" -Headers $rh

    Write-Output "$($c.name): status=$($exec.status) code=$($exec.responseStatusCode)"
  } catch {
    $msg = $_.Exception.Message
    if ($_.ErrorDetails.Message) { $msg = $_.ErrorDetails.Message }
    Write-Output "$($c.name): REQUEST-ERROR => $msg"
  }
}
