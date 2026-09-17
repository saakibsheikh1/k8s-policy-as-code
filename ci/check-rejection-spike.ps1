param(
    [int]$RejectedRequests = 0,
    [int]$Threshold = 3
)

Write-Host "Kyverno rejected admissions: $RejectedRequests"
Write-Host "Configured rejection threshold: $Threshold"

if ($RejectedRequests -ge $Threshold) {
    Write-Host "ALERT: Kyverno admission rejection spike detected."
    exit 1
}

Write-Host "OK: Rejection rate is below the alert threshold."
exit 0
