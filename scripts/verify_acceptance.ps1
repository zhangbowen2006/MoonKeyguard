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
moon run examples/baseline

# A malformed declaration must fail the explicit CI gate; this guards the
# parser-diagnostics path without pretending a failing command is a test pass.
moon run cmd/main -- --source "wat value=1" --fail-on-warning
if ($LASTEXITCODE -ne 1) {
  throw "expected parser diagnostics to return exit code 1, got $LASTEXITCODE"
}
Write-Host 'Parser gate negative test returned expected exit code 1'
Write-Host 'All local checks completed. This script does not publish to Mooncakes.'