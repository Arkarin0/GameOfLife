[CmdletBinding(PositionalBinding=$false)]
Param(
  # Standard options
  [string]$branchName = "master",  
  [switch]$build,
  [switch]$pack,
  [switch]$publish,
  [switch]$restore,
  [switch]$test,
  [switch]$all
)
Set-StrictMode -version 2.0
$ErrorActionPreference="Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    if ($branchName -eq "") {
      Write-Host "Must provide the build branchName with -branchName"
      exit 1
    }
  
    . (Join-Path $PSScriptRoot "build-utils.ps1")
    
  
    Ensure-DotnetSdk
    Push-Location $RepoRoot
  
    $simpleTest= !$build -and !$restore -and !$test -and !$pack -and !$publish

    $officialBuildId = "ManualTest"
    $configuration = "Release"

    if ($restore -or $all -or $simpleTest) {
        .\Restore.cmd -c $configuration -officialSourceBranchName $branchName -officialBuildId $officialBuildId
    }

    if ($build -or $all -or $simpleTest) {
        .\Build.cmd -c $configuration -officialSourceBranchName $branchName -officialBuildId $officialBuildId
    }

    if ($test -or $all -or $simpleTest) {
        .\Test.cmd -c $configuration -officialSourceBranchName $branchName -officialBuildId $officialBuildId
    }

    if ($pack -or $all) {
        .\eng\build.ps1 -pack -c $configuration -officialSourceBranchName $branchName -officialBuildId $officialBuildId
    }

    if ($publish -or $all) {
        .\eng\publish-assets.ps1 -configuration $configuration -test -BranchName $branchName
    }


    exit 0
  }
  catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    exit 1
  }