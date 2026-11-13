<#
  Split Fiction - Arabic translation installer (by Saad5400)
  https://github.com/Saad5400/SplitFiction-Arabic

  Finds every Split Fiction install on this PC (Steam, EA app, Epic Games,
  or any custom folder), downloads the latest translation release and puts
  it in <Game>\Split\Content\Paks.

  Usage (PowerShell):
    irm https://raw.githubusercontent.com/Saad5400/SplitFiction-Arabic/main/installer/install.ps1 | iex
  Options when running the file directly:
    -GamePath "D:\Games\Split Fiction"   use this folder, skip searching
    -Uninstall                           remove the translation
    -DryRun                              only show what would be done
    -Yes                                 don't ask questions (pick all installs found)
#>
[CmdletBinding()]
param(
  [string]$GamePath,
  [switch]$Uninstall,
  [switch]$DryRun,
  [switch]$Yes,
  [switch]$Pause,
  [string]$Repo = 'Saad5400/SplitFiction-Arabic',
  [string]$PakName = 'Saad5400_SplitFiction_Arabic_999_P.pak'
)

$ErrorActionPreference = 'Stop'
$ScriptUrl = "https://raw.githubusercontent.com/$Repo/main/installer/install.ps1"
# Older / third-party Arabic paks that conflict with this one. They get moved to a backup folder, not deleted.
$OldPaks = @('MohammadFadel1987_P.pak', 'zArabicTest_999_P.pak', 'Arabic_Test_P.pak')

function Say([string]$msg, [string]$color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Step([string]$msg) { Write-Host ''; Write-Host "==> $msg" -ForegroundColor Cyan }

function Test-GameDir([string]$dir) {
  if (-not $dir) { return $false }
  try { return (Test-Path -LiteralPath (Join-Path $dir 'Split\Content\Paks\pakchunk0-Windows.pak')) } catch { return $false }
}

function Get-SteamLibraries {
  $roots = New-Object System.Collections.Generic.List[string]
  foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
    try {
      $p = Get-ItemProperty -Path $k -ErrorAction Stop
      foreach ($v in @($p.SteamPath, $p.InstallPath)) { if ($v) { $roots.Add(($v -replace '/', '\')) } }
    } catch {}
  }
  $libs = New-Object System.Collections.Generic.List[string]
  foreach ($r in ($roots | Select-Object -Unique)) {
    $libs.Add($r)
    $vdf = Join-Path $r 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
      foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
        $libs.Add(($m.Groups[1].Value -replace '\\\\', '\'))
      }
    }
  }
  return $libs | Select-Object -Unique
}

function Find-GameDirs {
  $found = New-Object System.Collections.Generic.List[string]
  $add = { param($d, $src) if ($d -and (Test-GameDir $d)) { $full = (Resolve-Path -LiteralPath $d).Path.TrimEnd('\'); if (-not ($found -contains $full)) { $found.Add($full); Say "  found ($src): $full" 'Green' } } }

  # 1) Steam libraries (app id 2001120)
  foreach ($lib in Get-SteamLibraries) {
    $acf = Join-Path $lib 'steamapps\appmanifest_2001120.acf'
    $dirName = 'Split Fiction'
    if (Test-Path -LiteralPath $acf) {
      $m = [regex]::Match((Get-Content -LiteralPath $acf -Raw), '"installdir"\s+"([^"]+)"')
      if ($m.Success) { $dirName = $m.Groups[1].Value }
    }
    & $add (Join-Path $lib "steamapps\common\$dirName") 'Steam'
  }

  # 2) Windows "installed apps" registry (Steam, EA app, Epic and most launchers write here)
  $uninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                   'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
  foreach ($e in (Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Split Fiction*' })) {
    & $add $e.InstallLocation 'Installed apps'
  }

  # 3) EA app / Origin registry
  foreach ($k in 'HKLM:\SOFTWARE\WOW6432Node\EA Games\Split Fiction', 'HKLM:\SOFTWARE\EA Games\Split Fiction',
                 'HKLM:\SOFTWARE\WOW6432Node\Electronic Arts\Split Fiction', 'HKLM:\SOFTWARE\Electronic Arts\Split Fiction') {
    try { $p = Get-ItemProperty -Path $k -ErrorAction Stop; foreach ($n in 'Install Dir', 'InstallDir', 'Install Location') { & $add $p.$n 'EA app' } } catch {}
  }

  # 4) Epic Games launcher manifests
  $epic = Join-Path $env:ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
  if (Test-Path -LiteralPath $epic) {
    foreach ($f in Get-ChildItem -LiteralPath $epic -Filter *.item -ErrorAction SilentlyContinue) {
      try { $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json; if ($j.DisplayName -like '*Split Fiction*') { & $add $j.InstallLocation 'Epic Games' } } catch {}
    }
  }

  # 5) Common game folders on every drive
  $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Root -and (Test-Path -LiteralPath $_.Root) }
  $sub = 'Program Files\EA Games', 'Program Files (x86)\EA Games', 'EA Games', 'Program Files\Epic Games', 'Epic Games',
         'Program Files (x86)\Steam\steamapps\common', 'Program Files\Steam\steamapps\common', 'SteamLibrary\steamapps\common',
         'Steam\steamapps\common', 'Games\SteamLibrary\steamapps\common', 'Games\Steam\steamapps\common', 'Games', 'Games\Epic Games',
         'Games\EA Games', 'XboxGames', 'Program Files\WindowsApps'
  foreach ($d in $drives) { foreach ($s in $sub) { foreach ($n in 'Split Fiction', 'SplitFiction') { & $add (Join-Path $d.Root (Join-Path $s $n)) 'Folder' } } }

  return $found
}

function Search-AllDrives {
  $found = New-Object System.Collections.Generic.List[string]
  $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Root -and (Test-Path -LiteralPath $_.Root) }
  foreach ($d in $drives) {
    Say "  searching $($d.Root) ..."
    Get-ChildItem -LiteralPath $d.Root -Recurse -Filter 'pakchunk0-Windows.pak' -ErrorAction SilentlyContinue -Force |
      Where-Object { $_.DirectoryName -like '*\Split\Content\Paks' } | ForEach-Object {
        $g = (Get-Item -LiteralPath $_.DirectoryName).Parent.Parent.Parent.FullName
        if ((Test-GameDir $g) -and -not ($found -contains $g)) { $found.Add($g); Say "  found: $g" 'Green' }
      }
  }
  return $found
}

function Test-Admin { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }

function Test-Writable([string]$dir) {
  $probe = Join-Path $dir ('.write_test_' + [guid]::NewGuid().ToString('N'))
  try { [IO.File]::WriteAllText($probe, 'x'); Remove-Item -LiteralPath $probe -Force; return $true } catch { return $false }
}

function Restart-Elevated {
  Say 'The game folder needs administrator rights. Asking Windows for permission...' 'Yellow'
  $self = $PSCommandPath
  if (-not $self) { $self = Join-Path $env:TEMP 'SplitFiction-Arabic-install.ps1'; Invoke-WebRequest -UseBasicParsing -Uri $ScriptUrl -OutFile $self }
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$self`"", '-Pause')
  if ($GamePath) { $argList += @('-GamePath', "`"$GamePath`"") }
  if ($Uninstall) { $argList += '-Uninstall' }
  if ($DryRun) { $argList += '-DryRun' }
  if ($Yes) { $argList += '-Yes' }
  Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Verb RunAs | Out-Null
  exit 0
}

# -------------------------------------------------------------------------------------------------
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  Write-Host ''
  Write-Host '  Split Fiction - Arabic translation (Saad5400)' -ForegroundColor White
  Write-Host "  https://github.com/$Repo" -ForegroundColor DarkGray

  # --- locate the game -----------------------------------------------------------------------------
  Step 'Looking for Split Fiction on this PC'
  if ($GamePath) {
    if (-not (Test-GameDir $GamePath)) { throw "This folder is not a Split Fiction install: $GamePath (expected Split\Content\Paks\pakchunk0-Windows.pak inside)" }
    $games = @((Resolve-Path -LiteralPath $GamePath).Path.TrimEnd('\'))
  } else {
    $games = @(Find-GameDirs)
    if ($games.Count -eq 0) {
      Say '  Not found in the usual places.' 'Yellow'
      $ans = if ($Yes) { 'y' } else { Read-Host '  Search every drive? This can take a few minutes [Y/n]' }
      if ($ans -notmatch '^[nN]') { $games = @(Search-AllDrives) }
    }
    if ($games.Count -eq 0 -and -not $Yes) {
      $manual = Read-Host '  Paste the game folder path (the one that contains the "Split" folder), or press Enter to cancel'
      if ($manual) { $manual = $manual.Trim('"', ' '); if (Test-GameDir $manual) { $games = @($manual) } else { throw "Not a Split Fiction folder: $manual" } }
    }
  }
  if ($games.Count -eq 0) { throw 'Split Fiction was not found. Run again with -GamePath "<game folder>".' }

  if ($games.Count -gt 1 -and -not $Yes) {
    Say ''
    for ($i = 0; $i -lt $games.Count; $i++) { Say ("  [{0}] {1}" -f ($i + 1), $games[$i]) }
    $pick = Read-Host '  Install to which one? Number, or A for all [A]'
    if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $games.Count) { $games = @($games[[int]$pick - 1]) }
  }

  # --- elevation check -----------------------------------------------------------------------------
  $paksDirs = $games | ForEach-Object { Join-Path $_ 'Split\Content\Paks' }
  if (-not $DryRun -and -not (Test-Admin)) {
    foreach ($p in $paksDirs) { if (-not (Test-Writable $p)) { Restart-Elevated } }
  }

  # --- uninstall -----------------------------------------------------------------------------------
  if ($Uninstall) {
    Step 'Removing the Arabic translation'
    foreach ($p in $paksDirs) {
      $f = Join-Path $p $PakName
      if (Test-Path -LiteralPath $f) { if ($DryRun) { Say "  would remove $f" } else { Remove-Item -LiteralPath $f -Force; Say "  removed $f" 'Green' } }
      else { Say "  not installed in $p" }
    }
    Say ''; Say 'Done. The game is back to English.' 'Green'
    return
  }

  # --- download the latest release ---------------------------------------------------------------
  Step 'Downloading the latest translation'
  $tag = $null; $digest = $null
  try {
    $rel = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'SplitFiction-Arabic-installer' }
    $tag = $rel.tag_name
    $asset = $rel.assets | Where-Object { $_.name -eq $PakName } | Select-Object -First 1
    if ($asset -and $asset.digest -match '^sha256:([0-9a-f]{64})$') { $digest = $Matches[1] }
  } catch { Say '  (could not read release info, downloading anyway)' 'DarkGray' }
  if ($tag) { Say "  latest version: $tag" }
  $tmp = Join-Path $env:TEMP $PakName
  $url = "https://github.com/$Repo/releases/latest/download/$PakName"
  if ($DryRun) { Say "  would download $url" } else {
    $old = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp
    $ProgressPreference = $old
    $size = (Get-Item -LiteralPath $tmp).Length
    if ($size -lt 1MB) { throw "Download looks wrong ($size bytes)." }
    $hash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash.ToLower()
    if ($digest -and $hash -ne $digest) { throw "Checksum mismatch: expected $digest, got $hash" }
    Say ("  downloaded {0:N1} MB{1}" -f ($size / 1MB), $(if ($digest) { ', checksum OK' } else { '' })) 'Green'
  }

  # --- install -------------------------------------------------------------------------------------
  foreach ($p in $paksDirs) {
    Step "Installing to $p"
    foreach ($o in $OldPaks) {
      $of = Join-Path $p $o
      if (Test-Path -LiteralPath $of) {
        $bk = Join-Path $p '_old_arabic_backup'
        if ($DryRun) { Say "  would move old translation $o to $bk" } else {
          New-Item -ItemType Directory -Force -Path $bk | Out-Null
          Move-Item -LiteralPath $of -Destination (Join-Path $bk $o) -Force
          Say "  moved old translation $o to _old_arabic_backup (it conflicts with this one)" 'Yellow'
        }
      }
    }
    if ($DryRun) { Say "  would copy $PakName" } else {
      Copy-Item -LiteralPath $tmp -Destination (Join-Path $p $PakName) -Force
      Say "  installed $PakName" 'Green'
    }
  }
  if (-not $DryRun) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }

  Write-Host ''
  Write-Host '  Done! Start the game and set the language to English.' -ForegroundColor Green
  Write-Host '  In the settings it shows as: (Arabic) - by Saad5400' -ForegroundColor Green
  Write-Host '  To remove it later, run this installer with -Uninstall.' -ForegroundColor DarkGray
}
catch {
  Write-Host ''
  Write-Host ("  ERROR: " + $_.Exception.Message) -ForegroundColor Red
  $global:LASTEXITCODE = 1
}
finally {
  if ($Pause) { Write-Host ''; Read-Host '  Press Enter to close' | Out-Null }
}
