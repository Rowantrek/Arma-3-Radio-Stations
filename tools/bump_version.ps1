<#
.SYNOPSIS
Sets the mod version to today's date: YYYY.MM.DD.N.

.DESCRIPTION
Writes today's year, month and day into script_version.hpp. N is the release number on that day:
it goes up by one if the version is already today's date, and starts at 1 otherwise.
Month and day are written with two digits, which CfgPatches' numeric version needs to sort correctly.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\bump_version.ps1

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\bump_version.ps1 -Path AddonTemplate\addons\main\script_version.hpp
#>
param(
    [string]$Path = (Join-Path $PSScriptRoot '..\Arma3RadioStations\addons\main\script_version.hpp')
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$Path = (Resolve-Path -LiteralPath $Path).Path
$text = [IO.File]::ReadAllText($Path)

function Get-Define([string]$Name) {
    $match = [regex]::Match($text, "(?m)^#define $Name (\d+)")
    if (-not $match.Success) { throw "No '#define $Name <number>' in $Path" }
    [int]$match.Groups[1].Value
}

$today = Get-Date
$isToday = (Get-Define 'MAJOR') -eq $today.Year -and (Get-Define 'MINOR') -eq $today.Month -and (Get-Define 'PATCHLVL') -eq $today.Day
$build = if ($isToday) { (Get-Define 'BUILD') + 1 } else { 1 }

$values = @{ MAJOR = $today.ToString('yyyy'); MINOR = $today.ToString('MM'); PATCHLVL = $today.ToString('dd'); BUILD = "$build" }
foreach ($name in $values.Keys) {
    $text = [regex]::Replace($text, "(?m)^#define $name \d+", "#define $name $($values[$name])")
}
[IO.File]::WriteAllText($Path, $text, $utf8)

Write-Host ("Version {0}.{1}.{2}.{3} in {4}" -f $values.MAJOR, $values.MINOR, $values.PATCHLVL, $values.BUILD, $Path)
