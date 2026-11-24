param(
    [Parameter(Mandatory = $true)][string]$PackagePath
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Expected values come from the build props so a version bump cannot drift from this check.
$repoRoot = Split-Path -Parent $PSScriptRoot
[xml]$versionsProps = Get-Content (Join-Path $repoRoot 'Versions.props')
[xml]$packageProps = Get-Content (Join-Path $repoRoot 'ismkdc.props')
$expectedEf = @($versionsProps.Project.PropertyGroup | ForEach-Object { $_.EF11Version }) | Where-Object { $_ } | Select-Object -First 1
$expectedDriver = @($versionsProps.Project.PropertyGroup | ForEach-Object { $_.CSharpDriverVersion }) |
    Where-Object { $_ -and $_ -notlike '$(*' } | Select-Object -First 1
if ($env:DRIVER_VERSION) { $expectedDriver = $env:DRIVER_VERSION }
$expectedVersion = @($packageProps.Project.PropertyGroup | ForEach-Object { $_.PackageVersion }) | Where-Object { $_ } | Select-Object -First 1

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
if ($m.version -ne $expectedVersion) { $errors += "Version '$($m.version)' != '$expectedVersion'" }
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
elseif ($ef.version -ne $expectedEf) { $errors += "EF Core dependency '$($ef.version)' != '$expectedEf'" }
if (-not $drv) { $errors += 'missing MongoDB.Driver dependency' }
elseif ($drv.version -ne $expectedDriver) { $errors += "MongoDB.Driver dependency '$($drv.version)' != '$expectedDriver'" }

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
    exit 1
}
Write-Host "Package OK: $($m.id) $($m.version)" -ForegroundColor Green
