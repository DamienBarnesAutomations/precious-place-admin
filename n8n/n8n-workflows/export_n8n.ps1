# Export-N8n.ps1
param(
  [string[]]$IgnorePrefixes = @("cake")
)

$OutputDir     = Join-Path $PSScriptRoot "n8n_exports"
$SplitDir      = Join-Path $OutputDir "workflows"
$ContainerName = "n8n_app"
$ContainerPath = "/home/node/.n8n-files/workflows/n8n_exports"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $SplitDir  | Out-Null

# ---- Export all_workflows.json and all_credentials.json from container ----
Write-Host "Exporting workflows..."
docker exec $ContainerName n8n export:workflow --all --output=$ContainerPath/all_workflows.json
if ($LASTEXITCODE -ne 0) { Write-Error "Workflow export failed."; exit 1 }

Write-Host "Exporting credentials..."
docker exec $ContainerName n8n export:credentials --all --decrypted --output=$ContainerPath/all_credentials.json
if ($LASTEXITCODE -ne 0) { Write-Error "Credentials export failed."; exit 1 }

Write-Host "Copying files from container..."
docker cp "${ContainerName}:${ContainerPath}/all_workflows.json"   (Join-Path $OutputDir "all_workflows.json")
docker cp "${ContainerName}:${ContainerPath}/all_credentials.json" (Join-Path $OutputDir "all_credentials.json")

# ---- Clear SplitDir before writing ----
if (Test-Path $SplitDir) {
  Remove-Item (Join-Path $SplitDir "*.json") -Force
  Write-Host "Cleared existing files in $SplitDir"
}

# ---- Split into individual workflow files ----
Write-Host "`nSplitting into individual workflow files..."
Write-Host "Ignoring prefixes: $($IgnorePrefixes -join ', ')"

$workflows = Get-Content (Join-Path $OutputDir "all_workflows.json") -Raw | ConvertFrom-Json

$saved   = 0
$ignored = 0

# UTF8 without BOM encoder for Linux-compatible files
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($wf in $workflows) {
  $name = $wf.name

  # Check if workflow name starts with any ignored prefix (case-insensitive)
  $skip = $false
  foreach ($prefix in $IgnorePrefixes) {
    if ($name -ilike "$prefix*") {
      Write-Host "  Ignoring: $name"
      $skip = $true
      $ignored++
      break
    }
  }
  if ($skip) { continue }

  $wf.PSObject.Properties.Remove('versionCounter')

  $safeName = $name -replace '[^\w\-]', '_'
  $outFile  = Join-Path $SplitDir "$safeName.json"

  # Convert to JSON, replace CRLF with LF, write with UTF8 no BOM
  $json = $wf | ConvertTo-Json -Depth 20
  $json = $json -replace "`r`n", "`n"
  [System.IO.File]::WriteAllText($outFile, $json, $utf8NoBom)

  Write-Host "  Saved: $safeName.json"
  $saved++
}

Write-Host "`nDone. $saved workflows saved to: $SplitDir ($ignored ignored)."