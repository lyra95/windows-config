# AGENTS.md

Personal Windows dotfiles: WinGet DSC configuration documents, a PowerShell profile, and helper files. There is no build, test suite, or CI. Comments and commit messages are often in Korean; preserve that style in nearby code.

## Repository map

### WinGet configuration documents

Each YAML file is a standalone WinGet Configuration DSC document using schema 0.2 and ending in `properties.configurationVersion: 0.2.0`. Apply files independently; do not combine them.

Keep the configuration files and the assets they reference at the repository root. The repo is small, each YAML is invoked independently by filename, and DSC scripts use `${WinGetConfigRoot}` to find root-level assets such as `profile.ps1`, `.gitconfig`, and `claude-completion.ps1`. A directory split would add path indirection without clarifying ownership; if a real need arises to move files, update all references and invocation examples together.

- `base.yaml` — Developer Mode; WinGet DSC support module; user PATH and script-folder setup; WinGet packages (VS Code, PowerShell, Windows Terminal, Firefox, fzf, Starship, GNU Make); PowerShell modules (PSFzf, PSScriptAnalyzer); profile symlink.
- `apps.yaml` — general desktop applications installed from the `winget` source.
- `ai.yaml` — Codex CLI installed globally with npm; Claude desktop and Claude Code from WinGet; Claude Code completion symlink.
- `git.yaml` — Fork, Git, and GitHub CLI from WinGet; `.gitconfig` symlink.
- `etc.yaml` — KakaoTalk from the `msstore` source. Keep it separate from `apps.yaml`: reinstalling from msstore prompts again.
- `maplestory.yaml` — Nexon Plug from WinGet and Korean system locale configuration (locale change may require reboot).
- `nvidia.yaml` — NVIDIA App installed by downloading and running a versioned installer. The app's own UI is the documented update path.
- `podman.yaml` — Podman Desktop from WinGet; Podman CLI installed from the MSI bundled with Desktop; `$HOME\.local\bin\docker.exe` symlink to `podman.exe`.
- `wsl.yaml` — WSL from WinGet and Windows optional features for WSL/virtualization.

### Other files

- `profile.ps1` — PowerShell profile symlinked to `$PROFILE` by `base.yaml`. Keep this exact path and filename: DSC checks the target and the live shell depends on it.
- `claude-completion.ps1` — argument completer generated from `claude -h`; its header records the CLI version. `ai.yaml` symlinks it into `~/.config/my-ps-scripts/`. Regenerate when Claude CLI flags change.
- `update-non-winget.ps1` — updater for supported software installed outside WinGet. Keep it synchronized with non-WinGet installation resources.
- `.gitconfig` — symlinked to `%USERPROFILE%\.gitconfig` by `git.yaml`; do not rename.
- `makefile` — only the `format` target, which formats `profile.ps1`.
- `readme.md` — currently a short Korean TODO list.

## Common commands

Apply one config on the target machine in elevated PowerShell 7:

```powershell
Get-WinGetConfiguration -File <name>.yaml | Invoke-WinGetConfiguration
```

This requires the `Microsoft.WinGet.Configuration` module, installable with `Install-PSResource -Name Microsoft.WinGet.Configuration`. Do not apply configs with the `winget` CLI: the WSL optional-feature resources fail with a COM object parse error. The workaround is documented in `wsl.yaml`.

Format the profile with `make format`. This uses `Invoke-Formatter` from PSScriptAnalyzer and GNU Make at `C:\Program Files (x86)\GnuWin32\bin`; `base.yaml` installs/registers these. After editing `profile.ps1` in a live session, run `Reload`.

Run the non-WinGet updater in PowerShell 7:

```powershell
pwsh -File .\update-non-winget.ps1
pwsh -File .\update-non-winget.ps1 -WhatIf
```

The updater currently handles PowerShell Gallery modules and global npm packages (including `@openai/codex`). It does not update WinGet packages. NVIDIA App is updated through its own UI; Podman CLI is supplied by Podman Desktop and should be refreshed through that parent app.

## Configuration conventions

- Use `Microsoft.WinGet.DSC/WinGetPackage` for WinGet/MS Store packages, `PSDscResources/Script` for custom steps, and `PSDscResources/WindowsOptionalFeature` for Windows features.
- Put resource dependencies in resource-level `dependsOn`. Use `directives.securityContext: elevated` for symlinks or user-PATH changes that need elevation; follow the established patterns in `base.yaml`, `git.yaml`, and `podman.yaml`.
- `profile.ps1` dot-sources `~/.config/my-ps-scripts/*.ps1` in filename order and warns if one script fails. Add personal profile scripts to that directory rather than expanding the profile.
- When adding or changing software installed from a non-WinGet source (including a `PSDscResources/Script` installer), update `update-non-winget.ps1` in the same change if there is a reliable automated update method. If not, document the actual update path or limitation beside the install resource or in the updater. Do not add unrelated package managers speculatively. WinGet-managed applications remain out of this updater.
- Keep files UTF-8 without BOM. `make format` writes `profile.ps1` as `utf8NoBOM`; the profile also sets UTF-8 console encoding.
