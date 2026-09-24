.PHONY: format

SHELL := pwsh.exe
.SHELLFLAGS := -NoLogo -NoProfile -Command

format:
	Invoke-Formatter -ScriptDefinition (Get-Content -Raw -LiteralPath profile.ps1) | Set-Content -NoNewline -Encoding utf8NoBOM -LiteralPath profile.ps1
