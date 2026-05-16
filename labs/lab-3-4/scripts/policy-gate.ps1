# scripts/policy-gate.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$Workspace,
    
    [string]$PolicyDir = "policies",
    [string]$EvidenceDir = "evidence"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Policy Gate Check ===" -ForegroundColor Cyan
Write-Host "Workspace: $Workspace"
Write-Host "Policy Dir: $PolicyDir"
Write-Host ""

# Create evidence directory
New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

# Generate plan.json
Write-Host "Generating plan.json..." -ForegroundColor Yellow
Push-Location $Workspace
C:\tools\terraform.exe show -json tfplan | Out-File -FilePath "plan.json" -Encoding UTF8 -NoNewline
$PlanPath = Join-Path (Get-Location) "plan.json"
Pop-Location

# Namespaces to check
$Namespaces = @(
    "compliance.sc28_aws",
    "compliance.ac3_aws",
    "compliance.cm6_aws"
)

$AllPassed = $true
$Results = @()

foreach ($Namespace in $Namespaces) {
    Write-Host "Checking $Namespace..." -ForegroundColor Yellow
    
    $Output = C:\tools\conftest.exe test --policy $PolicyDir --namespace $Namespace --output json $PlanPath 2>&1
    
    # Parse JSON output
    $Result = $Output | ConvertFrom-Json
    
    # Check for failures
    $HasFailures = $false
    foreach ($Test in $Result) {
        if ($Test.failures -and $Test.failures.Count -gt 0) {
            $HasFailures = $true
            foreach ($Failure in $Test.failures) {
                Write-Host "  ❌ $($Failure.msg)" -ForegroundColor Red
            }
        }
    }
    
    if (!$HasFailures) {
        Write-Host "  ✅ PASS" -ForegroundColor Green
    } else {
        $AllPassed = $false
    }
    
    $Results += $Result
    Write-Host ""
}

# Save results
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath "$EvidenceDir\conftest-results.json" -Encoding UTF8

# Final verdict
Write-Host "=== Final Result ===" -ForegroundColor Cyan
if ($AllPassed) {
    Write-Host "✅ ALL POLICIES PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ POLICY VIOLATIONS DETECTED" -ForegroundColor Red
    Write-Host "See $EvidenceDir\conftest-results.json for details" -ForegroundColor Yellow
    exit 1
}