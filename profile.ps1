$PSDefaultParameterValues['*:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# startship
Invoke-Expression (@(&starship init powershell --print-full-init) -join "`n")

# file listup: Ctrl+t
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -ScriptBlock {
    Invoke-FzfPsReadlineHandlerProvider
}

# command history: Ctrl+r
Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -ScriptBlock {
    Invoke-FzfPsReadlineHandlerHistory
}

# mac-like open command
Set-Alias -Name open -Value Invoke-Item

# misc
Set-PSReadLineOption -HistoryNoDuplicates:$True

function Invoke-ExpressionGlobal {
    param([string]$Script)

    $beforeVars  = Get-Variable -Scope Global | Select-Object -ExpandProperty Name
    $beforeFuncs = Get-ChildItem function: | Select-Object -ExpandProperty Name

    Invoke-Expression $Script

    Get-Variable | Where-Object { $_.Name -notin $beforeVars } | ForEach-Object {
        Set-Variable -Name $_.Name -Value $_.Value -Scope Global
    }

    Get-ChildItem function: | Where-Object { $_.Name -notin $beforeFuncs } | ForEach-Object {
        Set-Item "function:global:$($_.Name)" -Value $_.ScriptBlock
    }
}

# podman
Set-Alias -Name docker -Value podman
Register-ArgumentCompleter -CommandName 'podman', 'docker' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    
    if (-not $global:__podmanCompleterBlock) {
        Invoke-ExpressionGlobal (podman completion powershell | Out-String)
    }

    $global:__podmanCompleterBlock.Invoke($wordToComplete, $commandAst, $cursorPosition)
}

# kubectl
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
  Set-Alias -Name k -Value kubectl
  Register-ArgumentCompleter -CommandName 'kubectl', 'k' -ScriptBlock {
      param($wordToComplete, $commandAst, $cursorPosition)
      
      if (-not $global:__kubectlCompleterBlock) {
          Invoke-ExpressionGlobal (kubectl completion powershell | Out-String)
      }

      $global:__kubectlCompleterBlock.Invoke($wordToComplete, $commandAst, $cursorPosition)
  }
}

function global:Add-Bom($Path) {
  $Path = Resolve-Path -Path $Path -ErrorAction Stop
  Set-Writable $Path

  # Read the first three bytes of the file
  $bytes = [System.IO.File]::ReadAllBytes($Path)[0..2]

  # Check if the bytes match the UTF-8 BOM (0xEF, 0xBB, 0xBF)
  if ($bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
    # BOM not found, so add it
    $bom = [byte[]](0xEF, 0xBB, 0xBF)
    $content = [System.IO.File]::ReadAllBytes($Path)
    [System.IO.File]::WriteAllBytes($Path, $bom + $content)
    Write-Output "BOM added to the file."
  } else {
    Write-Output "The file already starts with a UTF-8 BOM."
  }
}

function global:Test-Bom($Path) {
  $Path = Resolve-Path -Path $Path -ErrorAction Stop

  # Read the first three bytes of the file
  $bytes = [System.IO.File]::ReadAllBytes($Path)[0..2]
  # Check if the bytes match the UTF-8 BOM (0xEF, 0xBB, 0xBF)
  if ($bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
    Write-Output "NO BOM : $Path"
  } else {
    Write-Output "BOM : $Path"
  }
}

function global:Remove-Bom($Path) {
  $Path = Resolve-Path -Path $Path -ErrorAction Stop
  Set-Writable $Path

  # Read the first three bytes of the file
  $bytes = [System.IO.File]::ReadAllBytes($Path)[0..2]

  # Check if the bytes match the UTF-8 BOM (0xEF, 0xBB, 0xBF)
  if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    # BOM found, so remove it
    $content = [System.IO.File]::ReadAllBytes($Path)
    [System.IO.File]::WriteAllBytes($Path, $content[3..($content.Length - 1)])
    Write-Output "BOM removed from the file."
  } else {
    Write-Output "The file does not start with a UTF-8 BOM."
  }
}

function global:ConvertFrom-CRLF($Path) {
  $Path = Resolve-Path -Path $Path -ErrorAction Stop
  Set-Writable $Path

  # Read the content of the file
  $content = Get-Content -Path $Path -Raw

  # Replace CRLF (Windows) line endings with LF (Unix) line endings
  $content = $content -replace "`r`n", "`n"

  # Write the modified content back to the file
  Set-Content -Path $Path -Value $content

  Write-Output "CRLF line endings replaced with LF line endings."
}

function global:Set-Writable($Path) {
  Set-ItemProperty -Path $Path -Name IsReadOnly -Value $false
}

function global:Reload {
  . $PROFILE
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
}

function global:Search-Winget {
  $PACKAGE = & { $ErrorActionPreference = 'SilentlyContinue'; winget search "" | Select-Object -Skip 5 | fzf }
  if (-not $PACKAGE) { return }
  $list = $PACKAGE.Trim() -split '\s\s+'
  $ID = $list[1]
  if (-not $ID) { return }
  $ANSWER = Read-Host "Install ${ID}? (y/n)"
  if ($ANSWER -eq "y") {
    winget install "${ID}"
  }
}

# ~/.config/my-ps-scripts/*.ps1 로드 (파일명 순, 하나가 깨져도 나머지는 로드)
$myPsScripts = Join-Path $HOME '.config\my-ps-scripts'
if (Test-Path -Path $myPsScripts -PathType Container) {
  foreach ($s in Get-ChildItem -Path $myPsScripts -Filter '*.ps1' -File | Sort-Object Name) {
    try {
      . $s.FullName
    } catch {
      Write-Warning "프로필 스크립트 로드 실패: $($s.Name) - $($_.Exception.Message)"
    }
  }
}
