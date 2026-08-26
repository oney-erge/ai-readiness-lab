param(
  [ValidateSet("run", "doctor", "repair", "docker", "stop", "logs")]
  [string]$Action = "run",
  [switch]$NoBrowser
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
. .\scripts\install-utils.ps1
Initialize-Install -RepositoryRoot $PSScriptRoot -ProductName "AI Readiness Lab"
trap { Write-InstallFailure $_; Exit-InstallLock; exit 1 }
$UvVersion="0.12.5"; $NodeVersion="24.15.0"; $url="http://127.0.0.1:8123"
function Resolve-Uv{$cmd=Get-Command uv -ErrorAction SilentlyContinue;foreach($candidate in @($(if($cmd){$cmd.Source}),"$env:USERPROFILE\.local\bin\uv.exe","$env:USERPROFILE\.cargo\bin\uv.exe")){if($candidate-and(Test-Path -LiteralPath $candidate)){return $candidate}};return $null}
function Ensure-Uv{$uv=Resolve-Uv;if($uv){return $uv};$file=Join-Path $env:TEMP "airl-uv-$UvVersion.ps1";try{Save-InstallDownload -Url "https://astral.sh/uv/$UvVersion/install.ps1" -Destination $file -Label "uv download";& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $file}finally{Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue};$uv=Resolve-Uv;if(-not$uv){throw "uv installed but could not be located."};return $uv}
function Ensure-Node {
  $node=Get-Command node -ErrorAction SilentlyContinue
  if($node){$found=[version](& $node.Source -p "process.versions.node");if($found-ge[version]"22.22.2"){return (Get-Command npm.cmd -ErrorAction Stop).Source}}
  $platform=if($env:PROCESSOR_ARCHITECTURE-eq"ARM64"){"win-arm64"}else{"win-x64"}
  $archiveName="node-v$NodeVersion-$platform.zip";$runtime=Join-Path $PSScriptRoot ".runtime\node-v$NodeVersion-$platform";$npm=Join-Path $runtime "npm.cmd"
  if(Test-Path $npm){return $npm}
  New-Item -ItemType Directory -Force -Path .runtime|Out-Null
  $archive=Join-Path $env:TEMP $archiveName;$checksums=Join-Path $env:TEMP "airl-node-SHASUMS256.txt"
  try{
    Save-InstallDownload -Url "https://nodejs.org/dist/v$NodeVersion/$archiveName" -Destination $archive -Label "Node.js download"
    Save-InstallDownload -Url "https://nodejs.org/dist/v$NodeVersion/SHASUMS256.txt" -Destination $checksums -Label "Node.js checksum download"
    $line=Get-Content $checksums|Where-Object{$_-match"\s+$([regex]::Escape($archiveName))$"}|Select-Object -First 1
    if(-not$line){throw "The official checksum file does not list $archiveName."}
    $expected=($line-split'\s+')[0].ToLowerInvariant();$actual=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if($actual-ne$expected){throw "Node.js archive checksum mismatch."}
    $temp=Join-Path $PSScriptRoot ".runtime\node-extract";Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue;Expand-Archive -LiteralPath $archive -DestinationPath $temp
    Move-Item -LiteralPath (Join-Path $temp "node-v$NodeVersion-$platform") -Destination $runtime;Remove-Item -LiteralPath $temp -Recurse -Force
  }finally{Remove-Item -LiteralPath $archive,$checksums -Force -ErrorAction SilentlyContinue}
  if(-not(Test-Path $npm)){throw "Portable Node.js installation failed."};return $npm
}
function Test-Ready{try{Invoke-RestMethod -Uri "$url/health" -TimeoutSec 2|Out-Null;return $true}catch{return $false}}
function Wait-Ready{for($i=0;$i-lt 120;$i++){if(Test-Ready){return $true};Start-Sleep -Milliseconds 500};return $false}
if($Action-in@("docker","stop","logs")){$docker=Get-Command docker -ErrorAction SilentlyContinue;$engineRunning=$false;if($docker){docker info *> $null;$engineRunning=($LASTEXITCODE-eq 0)};if($Action-eq"stop"-and-not$engineRunning){Write-Host "The native server runs in the foreground. Press Ctrl+C in its terminal to stop it.";exit 0};if($Action-eq"logs"-and-not$engineRunning){Write-Host "The native server writes logs to its foreground terminal.";exit 0};if(-not$docker){throw "Docker is not installed."};if(-not$engineRunning){throw "Docker is installed but its engine is not running."};if($Action-eq"stop"){docker compose down;exit $LASTEXITCODE};if($Action-eq"logs"){docker compose logs --follow;exit $LASTEXITCODE};Enter-InstallLock;Assert-InstallFreeSpace -Path $PSScriptRoot -RequiredGB 3;docker compose up --detach --build;if($LASTEXITCODE-ne 0){throw "Docker Compose failed to start AI Readiness Lab."};if(-not(Wait-Ready)){docker compose logs;throw "AI Readiness Lab did not become ready at $url."};Complete-Install;Write-Host "AI Readiness Lab is ready at $url" -ForegroundColor Green;if(-not$NoBrowser){Start-Process $url};exit 0}
$python=Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if($Action-eq"doctor"){$ready=(Test-Path $python)-and(Test-Path .\frontend\dist\index.html);Write-Host "Environment: $(if($ready){'ready'}else{'incomplete, run .\run.bat once'})";if(Test-Ready){Write-Host "Server: $url"}else{Write-Host "Server: not running"};exit $(if($ready){0}else{1})}
Enter-InstallLock;Assert-InstallFreeSpace -Path $PSScriptRoot -RequiredGB 3
$uv=Ensure-Uv;Invoke-InstallRetry "Python installation" {$output=& $uv python install 3.11 2>&1;if($LASTEXITCODE-ne 0){throw "uv python install failed: $($output -join [Environment]::NewLine)"};$output|Write-Host};if(-not(Test-Path $python)){& $uv venv --python 3.11 .venv;if($LASTEXITCODE-ne 0){throw "uv venv exited with $LASTEXITCODE"}}
$pipArgs=@("pip","install","--python",$python,"--requirement","backend/requirements-desktop.txt");if($Action-eq"repair"){$pipArgs += "--reinstall"};Invoke-InstallRetry "Python dependency synchronization" {$output=& $uv @pipArgs 2>&1;if($LASTEXITCODE-ne 0){throw "uv pip install failed: $($output -join [Environment]::NewLine)"};$output|Write-Host}
$npm=Ensure-Node;$env:Path="$(Split-Path -Parent $npm);$env:Path";$frontendHash="$((Get-FileHash .\frontend\package-lock.json -Algorithm SHA256).Hash)|node=$NodeVersion";$marker=".\frontend\node_modules\.airl-build";$stored=if(Test-Path $marker){(Get-Content $marker -Raw).Trim()}else{""};if($Action-eq"repair"-or$stored-ne$frontendHash-or-not(Test-Path .\frontend\dist\index.html)){Push-Location frontend;try{Invoke-InstallRetry "frontend dependency installation" {$output=& $npm ci 2>&1;if($LASTEXITCODE-ne 0){throw "npm ci failed: $($output -join [Environment]::NewLine)"};$output|Write-Host};& $npm run build;if($LASTEXITCODE-ne 0){throw "frontend build exited with $LASTEXITCODE"}}finally{Pop-Location};Set-Content -LiteralPath $marker -Value $frontendHash -NoNewline}
Complete-Install
$env:PYTHONPATH=(Resolve-Path .\backend).Path
if($NoBrowser){Push-Location backend;try{& $python -m uvicorn app.main:app --host 127.0.0.1 --port 8123}finally{Pop-Location}}else{& $python .\desktop\launcher.py}
exit $LASTEXITCODE
