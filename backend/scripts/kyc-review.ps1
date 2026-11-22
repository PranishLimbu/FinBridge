# Review pending customer onboarding (KYC) applications as the supervisor.
#
#   .\scripts\kyc-review.ps1                         # list pending applications
#   .\scripts\kyc-review.ps1 -Approve CUSTOMER_ID     # approve one
#   .\scripts\kyc-review.ps1 -Approve all            # approve every pending one
#   .\scripts\kyc-review.ps1 -Reject CUSTOMER_ID -Reason "Photo unclear"
param(
  [string]$Approve,
  [string]$Reject,
  [string]$Reason,
  [string]$Api = 'http://localhost:4000/api',
  [string]$SupervisorId = 'SUP-001',
  [string]$Pin = '123456'
)
$ErrorActionPreference = 'Stop'

$login = Invoke-RestMethod -Method Post -Uri "$Api/auth/login" -ContentType 'application/json' `
  -Body (@{ agentId = $SupervisorId; pin = $Pin } | ConvertTo-Json)
$headers = @{ authorization = "Bearer $($login.token)" }

function Get-Pending { (Invoke-RestMethod -Uri "$Api/supervisor/overview" -Headers $headers).pendingKyc }

function Send-Decision([string]$id, [string]$decision, [string]$why) {
  $body = @{ decision = $decision }
  if ($why) { $body.reason = $why }
  Invoke-RestMethod -Method Post -Uri "$Api/supervisor/customers/$id/kyc" -Headers $headers `
    -ContentType 'application/json' -Body ($body | ConvertTo-Json) | Out-Null
  Write-Host "$($decision)d $id"
}

if ($Approve -eq 'all') {
  $pending = @(Get-Pending)
  if (-not $pending.Count) { Write-Host 'Nothing pending.' }
  foreach ($c in $pending) { Send-Decision $c.customerId 'approve' $null }
} elseif ($Approve) {
  Send-Decision $Approve 'approve' $null
} elseif ($Reject) {
  if (-not $Reason) { throw 'Give -Reason "..." (at least 5 characters) when rejecting.' }
  Send-Decision $Reject 'reject' $Reason
} else {
  $pending = @(Get-Pending)
  if ($pending.Count) { $pending | Format-Table customerId, name, createdByAgent, createdAt -AutoSize }
  else { Write-Host 'No applications waiting for review.' }
}
