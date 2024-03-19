param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$SpecsFolder
)

$allJsonFiles = Get-ChildItem -Path $SpecsFolder -Filter *.json -Recurse | ForEach-Object {$_.FullName } | Sort-Object

$specFiles = $allJsonFiles.Where({
  ($_ -notmatch "/(examples|scenarios|restler|common|common-types)/") -and
  ($_ -match "specification/[^/]+/(data-plane|resource-manager).*?/(preview|stable)/[^/]+/[^/]+\.json$")
})

$allCount = $allJsonFiles | Measure-Object | Select-Object -ExpandProperty Count
$specCount = $specFiles | Measure-Object | Select-Object -ExpandProperty Count

Write-Host $allCount $specCount

$specFiles | ForEach-Object -Parallel {
  Write-Host "Testing $_"
  npm exec --no -- oad compare $_ $_ -f /tmp
  if (-not $?) {
    throw "oad failed for $_"
  }
} -ThrottleLimit 16
