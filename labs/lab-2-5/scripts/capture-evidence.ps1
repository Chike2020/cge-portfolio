# capture-evidence.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$Workspace,
    
    [Parameter(Mandatory=$true)]
    [string]$RunId,
    
    [Parameter(Mandatory=$true)]
    [string]$Vault,
    
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"

# Create temp directory
$TempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "bundle-$RunId") -Force
$BundleDir = $TempDir.FullName

Write-Host "Collecting evidence from: $Workspace"
Write-Host "Bundle ID: $RunId"
Write-Host "Vault: $Vault"

# Get current timestamp
$CapturedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Collect plan.json
$PlanPath = Join-Path $Workspace "tfplan"
if (Test-Path $PlanPath) {
    Write-Host "Capturing plan..."
    Push-Location $Workspace
    C:\tools\terraform.exe show -json tfplan | Out-File -FilePath (Join-Path $BundleDir "plan.json") -Encoding UTF8
    Pop-Location
}

# Collect state.json
Write-Host "Capturing state..."
Push-Location $Workspace
C:\tools\terraform.exe show -json | Out-File -FilePath (Join-Path $BundleDir "state.json") -Encoding UTF8
Pop-Location

# Collect git commit info
$CommitPath = Join-Path $BundleDir "commit.txt"
Push-Location $Workspace
if (Test-Path .git) {
    git log -1 --pretty=full | Out-File -FilePath $CommitPath -Encoding UTF8
} else {
    "No git repository available" | Out-File -FilePath $CommitPath -Encoding UTF8
}
Pop-Location

# Terraform version
C:\tools\terraform.exe version | Out-File -FilePath (Join-Path $BundleDir "version.txt") -Encoding UTF8

# Create manifest with SHA256 hashes
Write-Host "Creating manifest..."
$Manifest = @()
Get-ChildItem $BundleDir -File | ForEach-Object {
    $Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    $Manifest += @{
        filename = $_.Name
        sha256 = $Hash
        size = $_.Length
        captured_at_utc = $CapturedAt
    }
}

$Manifest | ConvertTo-Json | Out-File -FilePath (Join-Path $BundleDir "manifest.json") -Encoding UTF8

# Create tar.gz bundle
Write-Host "Creating bundle..."
$BundlePath = Join-Path $env:TEMP "bundle-$RunId.tar.gz"
tar -czf $BundlePath -C $TempDir .

# Upload to S3
Write-Host "Uploading to vault..."
$Key = "runs/$RunId/bundle.tar.gz"

if ($Profile) {
    $UploadResult = aws s3api put-object --bucket $Vault --key $Key --body $BundlePath --profile $Profile --output json | ConvertFrom-Json
} else {
    $UploadResult = aws s3api put-object --bucket $Vault --key $Key --body $BundlePath --output json | ConvertFrom-Json
}

$VersionId = $UploadResult.VersionId

# Output receipt
$Receipt = @{
    run_id = $RunId
    vault = $Vault
    key = $Key
    version_id = $VersionId
    captured_at_utc = $CapturedAt
}

$Receipt | ConvertTo-Json -Compress
Write-Host "`nEvidence captured successfully!" -ForegroundColor Green

# Cleanup
Remove-Item $TempDir -Recurse -Force
Remove-Item $BundlePath -Force