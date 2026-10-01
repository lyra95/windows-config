# AGENTS.md

Personal dotfiles for a Windows machine: WinGet DSC YAML configs + PowerShell profile. No build, no tests, no CI. Repo comments and commit messages are often in Korean.

## Layout

- `*.yaml` — each file is a standalone WinGet Configuration DSC document (schema 0.2, ends with `configurationVersion: 0.2.0` under `properties`). Files are applied independently on the target machine; do not merge them.
- `profile.ps1` — PowerShell profile. `base.yaml` symlinks `$PROFILE` to it. Do not rename or move: DSC TestScripts check the exact target path and the live session breaks.
- `claude-completion.ps1` — `claude` CLI argument completer **generated from `claude -h`** (header notes the CLI version it was generated from). `ai.yaml` symlinks it into `~/.config/my-ps-scripts/`. Regenerate when the CLI's flags change.
- `.gitconfig` — symlinked to `%USERPROFILE%\.gitconfig` by `git.yaml`. Do not rename.
- `makefile` — single target: `format`.

## Commands

- Apply a config on the target machine (PowerShell 7, elevated):
  `Get-WinGetConfiguration -File <name>.yaml | Invoke-WinGetConfiguration`
  Requires the `Microsoft.WinGet.Configuration` module (`Install-PSResource -Name Microsoft.WinGet.Configuration`).
- Do not use the `winget` CLI to apply: WSL optional-feature resources fail with a ComObject parse error (workaround documented in `wsl.yaml` header).
- `make format` — reformats `profile.ps1` with `Invoke-Formatter` (from PSScriptAnalyzer; both are installed by `base.yaml`). Needs GNU Make from `C:\Program Files (x86)\GnuWin32\bin` on PATH, which `base.yaml` registers.
- After editing `profile.ps1` in a live session, run `Reload` (defined in the profile).

## Conventions

- DSC resource types: `Microsoft.WinGet.DSC/WinGetPackage` for packages, `PSDscResources/Script` (Get/Test/SetScript) for custom steps, `PSDscResources/WindowsOptionalFeature` for Windows features.
- Symlinks and user-PATH changes need `securityContext: elevated` in `directives`; cross-resource ordering uses `dependsOn` at the resource level (see `base.yaml`, `podman.yaml`).
- `etc.yaml` (KakaoTalk, msstore source) is intentionally kept out of `apps.yaml` because msstore packages re-prompt on reinstall. Do not merge it back.
- `profile.ps1` dot-sources every `~/.config/my-ps-scripts/*.ps1` in filename order; one broken script only warns. Put extra personal scripts in that folder instead of editing the profile.
- Files are UTF-8 without BOM (`make format` writes `utf8NoBOM`); `profile.ps1` also forces UTF-8 console encoding.
