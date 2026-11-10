param(
    [Parameter(Mandatory = $true)][string]$PackagePath
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $PackagePath))
try {
    $entries = @($zip.Entries | ForEach-Object { $_.FullName })
    $nuspecEntry = $zip.Entries | Where-Object { $_.FullName -like '*.nuspec' } | Select-Object -First 1
    $reader = New-Object System.IO.StreamReader($nuspecEntry.Open())
    [xml]$nuspec = $reader.ReadToEnd()
    $reader.Close()
}
finally {
    $zip.Dispose()
}

$m = $nuspec.package.metadata
$errors = @()
$dupes = $entries | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dupes) { $errors += 'duplicate package entries: ' + (($dupes | ForEach-Object { $_.Name }) -join ', ') }
if ($m.id -ne 'ismkdc.MongoDB.EntityFrameworkCore') { $errors += "PackageId '$($m.id)' != 'ismkdc.MongoDB.EntityFrameworkCore'" }
if ($m.version -ne '11.0.0') { $errors += "Version '$($m.version)' != '11.0.0'" }
if ($m.description -notmatch 'Unofficial') { $errors += 'Description must contain "Unofficial"' }
if (-not $m.license -or $m.license.type -ne 'file' -or $m.license.'#text' -ne 'LICENSE.md') { $errors += 'license must be the file LICENSE.md' }
if (-not $entries.Contains('lib/net11.0/MongoDB.EntityFrameworkCore.dll')) { $errors += 'missing lib/net11.0/MongoDB.EntityFrameworkCore.dll' }
foreach ($f in @('LICENSE.md', 'NOTICE.md', 'PACKAGE-README.md', 'packageIcon.png')) {
    if (-not $entries.Contains($f)) { $errors += "missing $f" }
}

$deps = @($m.dependencies.group.dependency)
$ef = $deps | Where-Object { $_.id -eq 'Microsoft.EntityFrameworkCore' }
$drv = $deps | Where-Object { $_.id -eq 'MongoDB.Driver' }
if (-not $ef) { $errors += 'missing Microsoft.EntityFrameworkCore dependency' }
elseif ($ef.version -ne '11.0.0') { $errors += "EF Core dependency '$($ef.version)' != '11.0.0'" }
if (-not $drv) { $errors += 'missing MongoDB.Driver dependency' }
elseif ($drv.version -ne '3.13.0') { $errors += "MongoDB.Driver dependency '$($drv.version)' != '3.13.0'" }

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
    exit 1
}
Write-Host "Package OK: $($m.id) $($m.version)" -ForegroundColor Green
