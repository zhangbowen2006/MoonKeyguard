$ErrorActionPreference = 'Stop'

Write-Host 'MoonKeyguard local acceptance checks'
moon version --all
moon check --deny-warn
moon build
moon test --deny-warn
moon fmt --check
moon info
moon package --list
moon run cmd/main -- --format json --metrics --suggest
moon run examples/basic
Write-Host 'All local checks completed. This script does not publish to Mooncakes.'
