$ErrorActionPreference = 'Stop'
$FlutterArguments = @($args)
$projectRoot = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
  throw "Supabase configuration file not found: $envPath"
}

$values = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
  if ($line -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
    $value = $Matches[2]
    if ($value.Length -ge 2 -and
        (($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') -or
         ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'"))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    $values[$Matches[1]] = $value
  }
}

foreach ($key in @('supabase_project_url', 'supabase_publishable_key')) {
  if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
    throw "Missing required .env setting: $key"
  }
}

if (-not $FlutterArguments -or $FlutterArguments.Count -eq 0) {
  $FlutterArguments = @('run')
}

$arguments = @($FlutterArguments) + @(
  "--dart-define=supabase_project_url=$($values['supabase_project_url'])",
  "--dart-define=supabase_publishable_key=$($values['supabase_publishable_key'])"
)
if ($values.ContainsKey('google_ID_client') -and
    -not [string]::IsNullOrWhiteSpace($values['google_ID_client'])) {
  $arguments += "--dart-define=google_ID_client=$($values['google_ID_client'])"
}

Push-Location $projectRoot
try {
  & flutter @arguments
  $exitCode = $LASTEXITCODE
}
finally {
  Pop-Location
}

exit $exitCode
