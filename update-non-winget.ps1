# Update non-WinGet software configured in this repository.
# Run in PowerShell 7.

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Continue'
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-UpdateStep {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Action
    )

    if (-not $PSCmdlet.ShouldProcess($Name, 'Update')) { return }

    Write-Host "`n==> $Name" -ForegroundColor Cyan
    try {
        $global:LASTEXITCODE = 0
        & $Action
        if ($LASTEXITCODE -is [int] -and $LASTEXITCODE -ne 0) {
            throw "프로세스가 종료 코드 $LASTEXITCODE 을(를) 반환했습니다."
        }
    }
    catch {
        $failures.Add("${Name}: $($_.Exception.Message)")
        Write-Warning "$Name 업데이트 실패: $($_.Exception.Message)"
    }
}

# PowerShell Gallery modules. Prefer the newer PSResourceGet command when present.
if (Get-Command Update-PSResource -ErrorAction SilentlyContinue) {
    Invoke-UpdateStep 'PowerShell modules (PSResourceGet)' {
        Update-PSResource -WhatIf:$WhatIfPreference -ErrorAction Stop
    }
}
elseif (Get-Command Update-Module -ErrorAction SilentlyContinue) {
    Invoke-UpdateStep 'PowerShell modules (PowerShellGet)' {
        Update-Module -Force -WhatIf:$WhatIfPreference -ErrorAction Stop
    }
}
else {
    Write-Host 'PowerShell module updater not found; skipping.' -ForegroundColor DarkGray
}

# ai.yaml installs @openai/codex as a global npm package.
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Invoke-UpdateStep 'Global npm packages' { npm update --global }
}

# nvidia.yaml과 같은 공식 다운로드 링크/버전 확인 로직 사용. 미설치 앱은 추가하지 않음.
$nvidiaScript = Join-Path $PSScriptRoot 'nvidia.ps1'
Invoke-UpdateStep 'NVIDIA App' {
    if ((& $nvidiaScript -Mode Get).Result) {
        & $nvidiaScript -Mode Set
    }
}

if ($failures.Count) {
    Write-Host "`n일부 업데이트가 실패했습니다:" -ForegroundColor Yellow
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "`n저장소에 정의된 비-WinGet 업데이트 작업을 마쳤습니다." -ForegroundColor Green
