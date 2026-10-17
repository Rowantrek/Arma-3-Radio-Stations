<#
.SYNOPSIS
Turns a folder of music into stations for Arma 3 Radio Stations.

.DESCRIPTION
Each subfolder of -Source becomes one station (folder name = station name). Each audio file in it
becomes a track (file name = track title), played in alphabetical order. Prefix file names with
01, 02, ... to set the order.

Files are converted to mono Ogg Vorbis with ffmpeg, and cfgSounds.hpp, cfgMusic.hpp and
stations.hpp are rewritten with the exact track lengths. Re-run it whenever the music changes;
files that are already converted and unchanged are skipped.

-Target is either:
  an addon folder (contains $PBOPREFIX$): audio goes to <addon>\data, configs to <addon>
  a mission folder (contains mission.sqm): audio and configs go to <mission>\radio

Needs ffmpeg and ffprobe on PATH (winget install Gyan.FFmpeg).

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source AddonTemplate\music -Target AddonTemplate\addons\main

.EXAMPLE
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source "D:\Radio" -Target "C:\Users\me\Documents\Arma 3 - Other Profiles\me\missions\MyMission.Altis"
#>
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Target,
    # Prefix for generated class names. Default: from the addon prefix, or "Mission".
    [string]$ClassPrefix,
    # Vorbis quality 0-10; 4 is about 0.5 MB per minute in mono.
    [ValidateRange(0, 10)][int]$Quality = 4
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object System.Text.UTF8Encoding($false)

# CfgSounds volumes. Only vehicles heard from outside (say3D) use them: say3D has no volume
# parameter, so this is the only place to set that level. In-vehicle and placed radios play the
# .ogg file directly and ignore them. <track>_PA is the louder copy used when a vehicle plays through its PA.
$outsideVolume = 1.25
$paVolume = 3.25 # 2.6x the outside volume

foreach ($tool in 'ffmpeg', 'ffprobe') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not found. Install ffmpeg (winget install Gyan.FFmpeg) and open a new terminal."
    }
}

function ConvertTo-ClassName([string]$Text) {
    $Text -replace '[^A-Za-z0-9]', ''
}

$Source = (Resolve-Path -LiteralPath $Source).Path
$Target = (Resolve-Path -LiteralPath $Target).Path
$prefixFile = Join-Path $Target '$PBOPREFIX$'

if (Test-Path -LiteralPath $prefixFile) {
    $pboPrefix = (Get-Content -LiteralPath $prefixFile -TotalCount 1).Trim().Trim('\')
    $configDir = $Target
    $dataDir = Join-Path $Target 'data'
    $soundPath = "\$pboPrefix\data"
    if (-not $ClassPrefix) {
        $ClassPrefix = (($pboPrefix -split '\\') | Where-Object { $_ -notin 'z', 'x', 'addons', 'main' }) -join '_'
    }
} elseif (Test-Path -LiteralPath (Join-Path $Target 'mission.sqm')) {
    $configDir = Join-Path $Target 'radio'
    $dataDir = $configDir
    $soundPath = 'radio'
    if (-not $ClassPrefix) { $ClassPrefix = 'Mission' }
} else {
    throw "Target must be an addon folder (with a `$PBOPREFIX`$ file) or a mission folder (with mission.sqm)."
}

$audioExtensions = '.ogg', '.mp3', '.wav', '.flac', '.m4a', '.aac', '.wma', '.opus'
$stationDirs = @(Get-ChildItem -LiteralPath $Source -Directory | Sort-Object Name)
if ($stationDirs.Count -eq 0) {
    throw "No station folders in $Source. Put each station's music in its own subfolder, e.g. $Source\My Station\song.mp3"
}

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$sounds = New-Object System.Collections.Generic.List[string]
$music = New-Object System.Collections.Generic.List[string]
$stations = New-Object System.Collections.Generic.List[string]
$usedOggs = New-Object System.Collections.Generic.HashSet[string]
$stationNames = @{}
$totalSeconds = 0

foreach ($dir in $stationDirs) {
    $stationClass = "${ClassPrefix}_$(ConvertTo-ClassName $dir.Name)"
    if ($stationNames.ContainsKey($stationClass)) {
        throw "Station folders '$($dir.Name)' and '$($stationNames[$stationClass])' both become class $stationClass. Rename one."
    }
    $stationNames[$stationClass] = $dir.Name

    $files = @(Get-ChildItem -LiteralPath $dir.FullName -File |
        Where-Object { $audioExtensions -contains $_.Extension.ToLower() } | Sort-Object Name)
    if ($files.Count -eq 0) {
        Write-Warning "Skipping station '$($dir.Name)': no audio files."
        continue
    }

    $trackClasses = @()
    $index = 0
    foreach ($file in $files) {
        $index++
        $trackClass = '{0}_{1:D2}' -f $stationClass, $index

        # Named after the source file, so reordering tracks doesn't force a re-convert
        $oggName = ('{0}_{1}.ogg' -f $stationClass, (ConvertTo-ClassName $file.BaseName)).ToLower()
        if ($usedOggs.Contains($oggName)) { $oggName = ('{0}_{1:D2}.ogg' -f $stationClass, $index).ToLower() }
        [void]$usedOggs.Add($oggName)
        $ogg = Join-Path $dataDir $oggName

        if (-not (Test-Path -LiteralPath $ogg) -or (Get-Item -LiteralPath $ogg).LastWriteTime -lt $file.LastWriteTime) {
            Write-Host "Converting $($dir.Name)\$($file.Name)"
            & ffmpeg -nostdin -y -loglevel error -i $file.FullName -vn -map_metadata -1 -ac 1 -ar 44100 -c:a libvorbis -q:a $Quality $ogg
            if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on $($file.FullName)" }
        }

        $durationText = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $ogg
        $duration = [math]::Round([double]::Parse(($durationText | Select-Object -First 1).Trim(), $inv), 2)
        $totalSeconds += $duration

        $title = $file.BaseName -replace '^\d+[\s._-]+', '' -replace '"', "'"
        $path = "$soundPath\$oggName"
        $sounds.Add([string]::Format($inv, 'class {0} {{ name = "{1}"; sound[] = {{"{2}", {3}, 1}}; titles[] = {{}}; }};', $trackClass, $title, $path, $outsideVolume))
        $sounds.Add([string]::Format($inv, 'class {0}_PA {{ name = "{1}"; sound[] = {{"{2}", {3}, 1}}; titles[] = {{}}; }};', $trackClass, $title, $path, $paVolume))
        $music.Add([string]::Format($inv, 'class {0} {{ name = "{1}"; sound[] = {{"{2}", 1, 1}}; duration = {3}; }};', $trackClass, $title, $path, $duration))
        $trackClasses += $trackClass
    }

    $trackList = ($trackClasses | ForEach-Object { "`"$_`"" }) -join ', '
    $stations.Add("class $stationClass {`r`n    displayName = `"$($dir.Name -replace '"', "'")`";`r`n    tracks[] = {$trackList};`r`n};")
    Write-Host ("Station {0} ({1}): {2} tracks" -f $dir.Name, $stationClass, $trackClasses.Count)
}

$header = "// Generated by import_music.ps1 from '$(Split-Path $Source -Leaf)'. Re-run the script after changing the music.`r`n"
[IO.File]::WriteAllText((Join-Path $configDir 'cfgSounds.hpp'), $header + ($sounds -join "`r`n") + "`r`n", $utf8)
[IO.File]::WriteAllText((Join-Path $configDir 'cfgMusic.hpp'), $header + ($music -join "`r`n") + "`r`n", $utf8)
[IO.File]::WriteAllText((Join-Path $configDir 'stations.hpp'), $header + ($stations -join "`r`n`r`n") + "`r`n", $utf8)

Get-ChildItem -LiteralPath $dataDir -Filter *.ogg | Where-Object { -not $usedOggs.Contains($_.Name.ToLower()) } | ForEach-Object {
    Write-Warning "Not used by any station (delete it to save space): $($_.FullName)"
}

$sizeMB = (Get-ChildItem -LiteralPath $dataDir -Filter *.ogg | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("Done: {0} stations, {1:N0} min of music, {2:N1} MB in {3}" -f $stations.Count, ($totalSeconds / 60), $sizeMB, $dataDir)
