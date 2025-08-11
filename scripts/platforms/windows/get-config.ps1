param (
    [string]$Key
)

$json = Get-Content -Raw -Path run.json | ConvertFrom-Json
$value = $json.$Key

Write-Host $value
