# First-run helper for Windows PowerShell.
# Usage (from the repo root):
#   .\scripts\run-local.ps1 -Godot "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
#   .\scripts\run-local.ps1 -Godot "C:\path\to\godot.exe" -Action test
#   .\scripts\run-local.ps1 -Godot "C:\path\to\godot.exe" -Action server

param(
	[Parameter(Mandatory = $true)]
	[string]$Godot,
	[ValidateSet("run", "test", "server", "import")]
	[string]$Action = "run"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path -LiteralPath $Godot)) {
	Write-Error "Godot executable not found: $Godot"
}

Write-Host "Importing game/ (required once so class_name types register)..."
& $Godot --headless --import --path game
if ($LASTEXITCODE -ne 0) {
	Write-Error "Godot import failed with exit code $LASTEXITCODE"
}

switch ($Action) {
	"import" { break }
	"test" {
		& $Godot --headless --path game -s addons/gut/gut_cmdln.gd -gexit
	}
	"server" {
		& $Godot --headless --path game -- --server --port=7777
	}
	default {
		& $Godot --path game
	}
}
