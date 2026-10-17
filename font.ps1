[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Get', 'Test', 'Set')]
    [string] $Mode
)

$ErrorActionPreference = 'Stop'

$installDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$versionFile = Join-Path $installDir 'D2Coding.version'
$releaseUri = 'https://api.github.com/repos/naver/d2-coding-font/releases/latest'
$fontMap = @(
    @{ Source = 'D2Coding/D2Coding-*.ttf'; Name = 'D2Coding-Regular.ttf'; RegistryName = 'D2Coding-Regular (TrueType)' },
    @{ Source = 'D2Coding/D2CodingBold-*.ttf'; Name = 'D2Coding-Bold.ttf'; RegistryName = 'D2Coding-Bold (TrueType)' },
    @{ Source = 'D2CodingLigature/D2Coding-*-ligature.ttf'; Name = 'D2Codingligature-Regular.ttf'; RegistryName = 'D2Codingligature-Regular (TrueType)' },
    @{ Source = 'D2CodingLigature/D2CodingBold-*-ligature.ttf'; Name = 'D2Codingligature-Bold.ttf'; RegistryName = 'D2Codingligature-Bold (TrueType)' }
)

function Get-LatestRelease {
    $release = Invoke-RestMethod -Uri $releaseUri
    $asset = $release.assets | Where-Object { $_.name -like 'D2Coding-*.zip' } | Select-Object -First 1
    if ($null -eq $asset) {
        throw 'D2Coding 최신 릴리스에서 다운로드할 ZIP 파일을 찾을 수 없습니다.'
    }

    return @{ Release = $release; Asset = $asset }
}

function Test-FontInstalled {
    param([Parameter(Mandatory)] [string] $Version)

    if (-not (Test-Path -Path $versionFile -PathType Leaf)) { return $false }
    if ((Get-Content -Path $versionFile -Raw).Trim() -ne $Version) { return $false }
    return @($fontMap | Where-Object { -not (Test-Path -Path (Join-Path $installDir $_.Name) -PathType Leaf) }).Count -eq 0
}

switch ($Mode) {
    'Get' {
        return $false
    }
    'Test' {
        try {
            $latest = Get-LatestRelease
            return Test-FontInstalled -Version $latest.Release.tag_name
        }
        catch {
            return $false
        }
    }
    'Set' {
        $latest = Get-LatestRelease
        if (Test-FontInstalled -Version $latest.Release.tag_name) { return }

        $null = New-Item -ItemType Directory -Force -Path $installDir
        $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        $null = New-Item -ItemType Directory -Path $workDir
        try {
            $archivePath = Join-Path $workDir $latest.Asset.name
            Invoke-WebRequest -Uri $latest.Asset.browser_download_url -OutFile $archivePath
            Expand-Archive -LiteralPath $archivePath -DestinationPath $workDir

            $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
            $null = New-Item -Path $registryPath -Force
            foreach ($font in $fontMap) {
                $sourcePath = Get-ChildItem -Path (Join-Path $workDir $font.Source) -File | Select-Object -First 1 -ExpandProperty FullName
                if (-not $sourcePath) { throw "릴리스에서 폰트 파일을 찾을 수 없습니다: $($font.Source)" }

                $destinationPath = Join-Path $installDir $font.Name
                Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
                New-ItemProperty -Path $registryPath -Name $font.RegistryName -Value $destinationPath -PropertyType String -Force | Out-Null
            }
            Set-Content -Path $versionFile -Value $latest.Release.tag_name -NoNewline
        }
        finally {
            Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
