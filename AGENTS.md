# AGENTS.md

Personal Windows dotfiles. No build, test suite, or CI. Preserve nearby Korean comment and commit-message style. Keep files UTF-8 without BOM.

## Repository map

Each YAML is an independent WinGet DSC schema 0.2 document ending in `properties.configurationVersion: 0.2.0`. Do not combine them. Keep configs and referenced assets at the repository root; scripts resolve assets through `${WinGetConfigRoot}`.

| File | Purpose |
| --- | --- |
| `base.yaml` | Latest Visual C++ x64 runtime; Developer Mode; WinGet support module; PATH; shell tools, modules, and profile symlink |
| `apps.yaml` | General desktop apps from `winget` |
| `ai.yaml` | Codex via global npm; Claude desktop/Code via WinGet; completion symlink |
| `git.yaml` | Fork, Git, GitHub CLI; `.gitconfig` symlink |
| `etc.yaml` | KakaoTalk via `msstore`; keep separate because reinstalling prompts again |
| `maplestory.yaml` | Nexon Plug; Korean system locale (may require reboot) |
| `nvidia.yaml` | Latest NVIDIA App from its official download page via root-level `nvidia.ps1` |
| `podman.yaml` | Podman Desktop; bundled CLI MSI; `~/.local/bin/docker.exe` symlink to Podman |
| `wsl.yaml` | WSL and optional Windows features; special execution path below |
| `font.yaml` | D2Coding fonts for the current user via root-level `font.ps1` |
| `profile.ps1` | Symlinked to `$PROFILE`; preserve this filename and path |
| `.gitconfig` | Symlinked to `%USERPROFILE%\.gitconfig`; do not rename |
| `claude-completion.ps1` | Generated from `claude -h`; header records version; regenerate when flags change |
| `update-non-winget.ps1` | PowerShell Gallery, global npm, and installed NVIDIA App updater |
| `makefile` | Only `format`, for `profile.ps1` |
| `readme.md` | Korean TODO list |

## Apply and verify

Run from the repository root as the intended Windows user. On a fresh machine, install the shared Visual C++ x64 runtime **before** running configuration:

```powershell
winget install --id Microsoft.VCRedist.2015+.x64 --exact --source winget --scope machine
winget configure -f .\base.yaml
winget configure test -f .\base.yaml
```

Without the runtime, WinGet 1.29.380's configuration worker crashed with `0xe0434352` while loading `WindowsPackageManager.dll`. The YAML resource cannot bootstrap its own worker; `useLatest: true` handles later runtime upgrades. On subsequent runs, apply/test the desired YAML independently.

Keep normal runs in the intended user's session and approve resource-specific UAC prompts. Do not elevate everything just to suppress prompts. User context does not enforce user-only installation: package scopes are not explicitly constrained. The runtime and Developer Mode are machine-wide.

For **`wsl.yaml` only**, use elevated PowerShell 7 and the module workaround for the CLI's optional-feature COM parsing error:

```powershell
Install-PSResource -Name Microsoft.WinGet.Configuration -Scope CurrentUser
Get-WinGetConfiguration -File .\wsl.yaml | Invoke-WinGetConfiguration
```

See `wsl.yaml` for details. The module is not required for normal CLI runs.

If DSC reports duplicate module versions, inspect `$env:PSModulePath` and `%LOCALAPPDATA%\Microsoft\WinGet\Configuration\Modules`. Keep a usable installed copy and move duplicates outside module search paths into a backup. This occurred with `Microsoft.WinGet.DSC` in the cache and `C:\Program Files\PowerShell\Modules`.

## Recommended application order

Apply only the configurations you need, one file at a time:

1. `base.yaml` — shared prerequisites and shell setup; reopen the terminal afterward to refresh PATH.
2. `font.yaml` — fonts for the terminal and editor.
3. `git.yaml` — Git tools and identity/configuration.
4. `apps.yaml` — general desktop applications.
5. `ai.yaml` — AI tools; requires working Node.js/npm, which no YAML currently installs.
6. `wsl.yaml` — use the PowerShell workaround above; complete any required reboot before using Podman's WSL backend.
7. `podman.yaml` — container tools and Docker compatibility link.
8. `nvidia.yaml` — optional NVIDIA App for compatible hardware.
9. `etc.yaml` — optional MS Store app, kept separate for its prompts.
10. `maplestory.yaml` — optional game setup; locale changes may require a final reboot.

This is a suggested workflow, not a dependency chain. The important boundaries are the runtime bootstrap before configuration, base shell setup before dependent tools, npm before `ai.yaml`, and enabled WSL before using Podman.

## Editing conventions

- Resources: `Microsoft.WinGet.DSC/WinGetPackage` for WinGet/MS Store, `PSDscResources/Script` for custom steps, `PSDscResources/WindowsOptionalFeature` for Windows features.
- Put dependencies in resource-level `dependsOn`. Use `directives.securityContext: elevated` only where needed; follow existing symlink patterns.
- Check helper scripts under `Set-StrictMode -Version Latest`, as used by DSC. Registry entries may lack properties such as `DisplayName`; check property existence before accessing them.
- Add personal shell scripts to `~/.config/my-ps-scripts/`; the profile dot-sources `*.ps1` in filename order and warns on failures. Avoid expanding the profile for these scripts.
- After editing the profile, run `make format` (PSScriptAnalyzer; GNU Make at `C:\Program Files (x86)\GnuWin32\bin`), then `Reload` in the live session.
- When changing non-WinGet installers, update `update-non-winget.ps1` in the same change if reliable automation exists; otherwise document the update path beside the resource or in the updater. Do not add speculative package managers or WinGet apps to this updater.

## Non-WinGet updates

Run in PowerShell 7:

```powershell
pwsh -File .\update-non-winget.ps1 -WhatIf
pwsh -File .\update-non-winget.ps1
```

Handles PowerShell Gallery modules, global npm packages (including Codex), and installed NVIDIA App. `nvidia.ps1` resolves the official x64/ARM64 download link, skips equal/newer versions, verifies the NVIDIA signature, and checks installer exit code and installed version. A changed page/link format fails explicitly; keep it synchronized with NVIDIA's download page. Update Podman CLI through Podman Desktop.
