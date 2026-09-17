$ErrorActionPreference = 'Stop'

# PowerShell's ErrorActionPreference does not reliably stop on native nonzero
# exits. Check every tool explicitly, including the expected negative case.
function Invoke-CheckedMoon {
  param(
    [string[]]$MoonArgs,
    [int]$ExpectedExitCode = 0
  )
  & moon @MoonArgs
  $actualExitCode = $LASTEXITCODE
  if ($actualExitCode -ne $ExpectedExitCode) {
    throw "moon $($MoonArgs -join ' '): expected exit $ExpectedExitCode, got $actualExitCode"
  }
}

Write-Host 'MoonKeyguard local acceptance checks'
Invoke-CheckedMoon -MoonArgs @('version', '--all')
Invoke-CheckedMoon -MoonArgs @('check', '--deny-warn')
Invoke-CheckedMoon -MoonArgs @('build')
Invoke-CheckedMoon -MoonArgs @('test', '--deny-warn')
Invoke-CheckedMoon -MoonArgs @('fmt', '--check')
Invoke-CheckedMoon -MoonArgs @('info')
git diff --exit-code -- '*.mbti'
if ($LASTEXITCODE -ne 0) {
  throw 'Public API snapshots differ from the committed version or git diff failed'
}
Invoke-CheckedMoon -MoonArgs @('package', '--list')
Invoke-CheckedMoon -MoonArgs @('run', 'cmd/main', '--', '--format', 'json', '--metrics', '--suggest')
Invoke-CheckedMoon -MoonArgs @('run', 'examples/basic')
Invoke-CheckedMoon -MoonArgs @('run', 'examples/baseline')

# A malformed declaration must fail the explicit CI gate; this guards the
# parser-diagnostics path without pretending a failing command is a test pass.
Invoke-CheckedMoon -MoonArgs @('run', 'cmd/main', '--', '--source', 'wat value=1', '--fail-on-warning') -ExpectedExitCode 2
Write-Host 'Parser negative test returned expected input-error exit code 2'
node scripts/test_cli.mjs wasm
if ($LASTEXITCODE -ne 0) { throw 'CLI subprocess regression tests failed' }
node scripts/test_vscode.mjs
if ($LASTEXITCODE -ne 0) { throw 'VS Code consumer contract tests failed' }
node scripts/benchmark.mjs --quick
if ($LASTEXITCODE -ne 0) { throw 'Measured benchmark smoke test failed' }
Write-Host 'All local checks completed. This script does not publish to Mooncakes.'
