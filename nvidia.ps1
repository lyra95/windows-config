[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Get', 'Test', 'Set')]
    [string] $Mode
)

$ErrorActionPreference = 'Stop'

function Get-InstalledVersion {
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $versions = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
        Where-Object {
            $_.PSObject.Properties['DisplayName'] -and
            $_.PSObject.Properties['DisplayVersion'] -and
            $_.DisplayName -match '^NVIDIA App(?: \d+(?:\.\d+){1,3})?$' -and
            $_.DisplayVersion
        } |
        ForEach-Object { [version]$_.DisplayVersion }
    return $versions | Sort-Object -Descending | Select-Object -First 1
}

function Get-LatestInstaller {
    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    if ($architecture -notin 'x64', 'arm64') {
        throw "NVIDIA App 설치를 지원하지 않는 아키텍처입니다: $architecture"
    }

    # 공식 페이지의 아키텍처별 다운로드 링크를 사용하고, 임의의 호스트/경로는 허용하지 않음.
    $page = Invoke-WebRequest -Uri 'https://www.nvidia.com/en-us/software/nvidia-app/' -UseBasicParsing -TimeoutSec 60
    $pattern = '^https://us\.download\.nvidia\.com/nvapp/client/(?<version>\d+(?:\.\d+){3})/' +
        $architecture + '/NVIDIA_app_v\k<version>_' + $architecture + '\.exe$'
    $installers = foreach ($link in $page.Links) {
        if ($link.href -match $pattern) {
            [pscustomobject]@{ Uri = $link.href; Version = [version]$Matches.version }
        }
    }
    $latest = $installers | Sort-Object Version -Descending | Select-Object -First 1
    if ($null -eq $latest) {
        throw 'NVIDIA 공식 페이지에서 최신 설치 파일을 찾을 수 없습니다. 다운로드 링크 형식을 확인하세요.'
    }
    return $latest
}

if ($Mode -eq 'Get') {
    return @{ Result = [string](Get-InstalledVersion) }
}

$latest = Get-LatestInstaller
$installed = Get-InstalledVersion
$upToDate = $null -ne $installed -and $installed -ge $latest.Version
if ($Mode -eq 'Test') { return $upToDate }
if ($upToDate) { return }

$installerPath = Join-Path ([IO.Path]::GetTempPath()) ("NVIDIA_app_$([guid]::NewGuid()).exe")
try {
    Write-Host "NVIDIA App $($latest.Version) 다운로드 및 설치"
    Invoke-WebRequest -Uri $latest.Uri -OutFile $installerPath -UseBasicParsing -TimeoutSec 1800
    $signature = Get-AuthenticodeSignature -LiteralPath $installerPath
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(?:^|,\s*)O=NVIDIA Corporation(?:,|$)') {
        throw 'NVIDIA 설치 파일의 유효한 NVIDIA Corporation 서명을 확인할 수 없습니다.'
    }

    $process = Start-Process -FilePath $installerPath -ArgumentList '/s' -Wait -PassThru
    if ($process.ExitCode -notin 0, 3010) {
        throw "NVIDIA App 설치 실패 (exit $($process.ExitCode))."
    }
    $installed = Get-InstalledVersion
    if ($null -eq $installed -or $installed -lt $latest.Version) {
        throw "NVIDIA App 설치 후 버전을 확인할 수 없습니다. 필요한 버전: $($latest.Version)"
    }
    if ($process.ExitCode -eq 3010) { Write-Warning 'NVIDIA App 설치를 완료하려면 재부팅이 필요합니다.' }
}
finally {
    if (Test-Path -LiteralPath $installerPath) {
        Remove-Item -LiteralPath $installerPath -Force
    }
}
