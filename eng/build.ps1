#This scripts is copied from https://github.com/dotnet/roslyn and modifed for my purpose.

#
# This script controls the Roslyn build process. This encompasess everything from build, testing to
# publishing of NuGet packages. The intent is to structure it to allow for a simple flow of logic
# between the following phases:
#
#   - restore
#   - build
#   - sign
#   - pack
#   - test
#   - publish
#
# Each of these phases has a separate command which can be executed independently. For instance
# it's fine to call `build.ps1 -build -testDesktop` followed by repeated calls to
# `.\build.ps1 -testDesktop`.

[CmdletBinding(PositionalBinding=$false)]
param (
  [string][Alias('c')]$configuration = "Debug",
  [string][Alias('v')]$verbosity = "m",
  [string]$msbuildEngine = "vs",

  # Actions
  [switch][Alias('r')]$restore,
  [switch][Alias('b')]$build,
  [switch]$rebuild,
#   [switch]$sign,
  [switch]$pack,
  # [switch]$publish,
#   [switch]$launch,
  [switch]$help,

  # Options
#   [switch]$bootstrap,
  # [string]$bootstrapConfiguration = "Release",
#   [switch][Alias('bl')]$binaryLog,
#   [switch]$buildServerLog,
#   [switch]$ci,
#   [switch]$collectDumps,
#   [switch][Alias('a')]$runAnalyzers,
#   [switch]$skipDocumentation = $false,
#   [switch][Alias('d')]$deployExtensions,
#   [switch]$prepareMachine,
  [switch]$warnAsError = $false,
  [switch]$sourceBuild = $false,
#   [switch]$oop64bit = $true,
#   [switch]$lspEditor = $false,

  # official build settings
  [string]$officialBuildId = "",
#   [string]$officialSkipApplyOptimizationData = "",
  [string]$officialSkipTests = "",
  [string]$officialSourceBranchName = "",
#   [string]$officialIbcDrop = "",
#   [string]$officialVisualStudioDropAccessToken = "",

  # Test actions
#   [switch]$test32,
#   [switch]$test64,
#   [switch]$testVsi,
   [switch][Alias('test')]$testDesktop,
#   [switch]$testCoreClr,
#   [switch]$testCompilerOnly = $false,
#   [switch]$testIOperation,
#   [switch]$testUsedAssemblies,
#   [switch]$sequential,
#   [switch]$helix,
#   [string]$helixQueueName = "",
  [switch]$testWMSDetectionApp,

  [parameter(ValueFromRemainingArguments=$true)][string[]]$properties)

  Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"
$solution = "GameOfLife.sln"

function Print-Usage() {
    Write-Host "Common settings:"
    Write-Host "  -configuration <value>    Build configuration: 'Debug' or 'Release' (short: -c)"
    Write-Host "  -verbosity <value>        Msbuild verbosity: q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]"
    # Write-Host "  -deployExtensions         Deploy built vsixes (short: -d)"
    # Write-Host "  -binaryLog                Create MSBuild binary log (short: -bl)"
    # Write-Host "  -buildServerLog           Create Roslyn build server log"
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  -restore                  Restore packages (short: -r)"
    Write-Host "  -build                    Build main solution (short: -b)"
    Write-Host "  -rebuild                  Rebuild main solution"
    Write-Host "  -pack                     Build NuGet packages and installer"
    # Write-Host "  -sign                     Sign our binaries"
    # Write-Host "  -publish                  Publish build artifacts (e.g. symbols)"
    # Write-Host "  -launch                   Launch Visual Studio in developer hive"
    Write-Host "  -help                     Print help and exit"
    Write-Host ""
    Write-Host "Test actions"
    # Write-Host "  -test32                   Run unit tests in the 32-bit runner"
    # Write-Host "  -test64                   Run unit tests in the 64-bit runner"
    Write-Host "  -testDesktop              Run Desktop unit tests (short: -test)"
    # Write-Host "  -testCoreClr              Run CoreClr unit tests"
    # Write-Host "  -testCompilerOnly         Run only the compiler unit tests"
    # Write-Host "  -testVsi                  Run all integration tests"
    # Write-Host "  -testIOperation           Run extra checks to validate IOperations"
    # Write-Host "  -testUsedAssemblies       Run extra checks to validate used assemblies feature"
    Write-Host "  -testWMSDetectionApp       Run extra checks to validate Compatibility with the WMSDetectionApp"
    Write-Host ""
    Write-Host "Advanced settings:"
    # Write-Host "  -ci                       Set when running on CI server"
    # Write-Host "  -bootstrap                Build using a bootstrap compilers"
    # Write-Host "  -bootstrapConfiguration   Build configuration for bootstrap compiler: 'Debug' or 'Release'"
    Write-Host "  -msbuildEngine <value>    Msbuild engine to use to run build ('dotnet', 'vs', or unspecified)."
    # Write-Host "  -collectDumps             Collect dumps from test runs"
    # Write-Host "  -runAnalyzers             Run analyzers during build operations (short: -a)"
    # Write-Host "  -skipDocumentation        Skip generation of XML documentation files"
    # Write-Host "  -prepareMachine           Prepare machine for CI run, clean up processes after build"
    Write-Host "  -useGlobalNuGetCache      Use global NuGet cache."
    Write-Host "  -warnAsError              Treat all warnings as errors"
    # Write-Host "  -sourceBuild              Simulate building source-build"
    Write-Host ""
    Write-Host "Official build settings:"
    Write-Host "  -officialBuildId                                  An official build id, e.g. 20190102.3"
    Write-Host "  -officialSkipTests <bool>                         Pass 'true' to not run tests"
    # Write-Host "  -officialSkipApplyOptimizationData <bool>         Pass 'true' to not apply optimization data"
    Write-Host "  -officialSourceBranchName <string>                The source branch name"
    # Write-Host "  -officialIbcDrop <string>                         IBC data drop to use (e.g. 'ProfilingOutputs/DevDiv/VS/..')."
    # Write-Host "                                                    'default' for the most recent available for the branch."
    # Write-Host "  -officialVisualStudioDropAccessToken <string>     The access token to access OptProf data drop"
    Write-Host ""
    Write-Host "Command line arguments starting with '/p:' are passed through to MSBuild."
  }

  # Process the command line arguments and establish defaults for the values which are not
# specified.
#
# In this function it's okay to use two arguments to extend the effect of another. For
# example it's okay to look at $testVsi and infer $runAnalyzers. It's not okay though to infer
# $build based on say $testDesktop. It's possible the developer wanted only for testing
# to execute, not any build.
function Process-Arguments() {
  function OfficialBuildOnly([string]$argName) {
    if ((Get-Variable $argName -Scope Script).Value) {
      if (!$officialBuildId) {
        Write-Host "$argName can only be specified for official builds"
        exit 1
      }
    } else {
      if ($officialBuildId) {
        Write-Host "$argName must be specified in official builds"
        exit 1
      }
    }
  }

  if ($help -or (($properties -ne $null) -and ($properties.Contains("/help") -or $properties.Contains("/?")))) {
       Print-Usage
       exit 0
  }

  # OfficialBuildOnly "officialSkipTests"
  # OfficialBuildOnly "officialSkipApplyOptimizationData"
  # OfficialBuildOnly "officialSourceBranchName"
  # OfficialBuildOnly "officialVisualStudioDropAccessToken"

  # if ($officialBuildId) {
  #   $script:useGlobalNuGetCache = $false
  #   $script:collectDumps = $true
  #   $script:testDesktop = ![System.Boolean]::Parse($officialSkipTests)
  #   $script:applyOptimizationData = ![System.Boolean]::Parse($officialSkipApplyOptimizationData)
  # } else {
  #   $script:applyOptimizationData = $false
  # }


  # if ($test32 -and $test64) {
  #   Write-Host "Cannot combine -test32 and -test64"
  #   exit 1
  # }

  # $anyUnit = $testDesktop -or $testCoreClr
  # if ($anyUnit -and $testVsi) {
  #   Write-Host "Cannot combine unit and VSI testing"
  #   exit 1
  # }

  # if ($testVsi) {
  #   # Avoid spending time in analyzers when requested, and also in the slowest integration test builds
  #   $script:runAnalyzers = $false
  #   $script:bootstrap = $false
  # }

  # if ($build -and $launch -and -not $deployExtensions) {
  #   Write-Host -ForegroundColor Red "Cannot combine -build and -launch without -deployExtensions"
  #   exit 1
  # }

  # if ($bootstrap) {
  #   $script:restore = $true
  # }

  # $script:test32 = -not $test64

  foreach ($property in $properties) {
    if (!$property.StartsWith("/p:", "InvariantCultureIgnoreCase")) {
      Write-Host "Invalid argument: $property"
      Print-Usage
      exit 1
    }
  }
}

  function BuildSolution() {
     
    Write-Host "$($solution):"
    if ($restore -or $rebuild -or $build ) {
      Write-Host "Generating automated code:" -ForegroundColor "Green"
      #call your testcode generator here.
      write-warning "No testcodegenerator present."
      Write-Host ""
    }

   BuildSolution-Core
  }

     
    

  function BuildSolution-Core()
  {
    Write-Host "Building solution:" -ForegroundColor "Green"

  
    $projects = Join-Path $RepoRoot $solution
    $toolsetBuildProj = InitializeToolset
    $packageSuffix = "abc" #get suffix depending on the Branch
     
    if ($restore) {
      $args += " /t:restore"
    }

    if ($rebuild) {
      $args += " /t:rebuild"
    }
    elseif ($build) {
      $args += " /t:build"
    }

    $packageData = GetBranchPublishData $officialSourceBranchName
    if($pack -and $packageData){
      $args += " /t:pack"        
      $kind = $packageData.nugetKind
      $args += " /p:PackageOutputPath=`"$PackagesDir\$kind`""
    }

    if ($officialSourceBranchName) {
      $args += " /p:Branch=`"$officialSourceBranchName`""
    }

    # if ($officialBuildId) {
    #   $args += " /p:OfficialBuildId=`"$officialBuildId`""
    # }
    
   
   
    #For now, we allow warning in the build. It is nessecery because we have reimplemented the solution and in previos project we didn't take care of warnings.
    #Now we have over 4000 warning to take care of. Till this is solved.
    $warnAsError = $false
    $treatWarningAsError = $false
    $args += " /p:NoWarn=1591" #ignore warning: Missing XML Dokumentation

    Write-Host "Confguration: " $configuration
    Write-Host "args        : " $args

    try {
     Run-MSBuild "`"$projects`"" -warnAsError:$warnAsError -treatWarningAsError:$treatWarningAsError $args
    }
    finally {
      ${env:ROSLYNCOMMANDLINELOGFILE} = $null
    }
  }

  # Core function for running our unit / integration tests tests
function TestUsingRunTests() {
  
  $projectFilePath = $solution

  

  # Tests need to locate .NET Core SDK
  $dotnet = InitializeDotNetCli

  # original, consider to implement the MS shema
  # $runTests = GetProjectOutputBinary "RunTests.dll" -tfm "netcoreapp3.1"
  #
  # if (!(Test-Path $runTests)) {
  #   Write-Host "Test runner not found: '$runTests'. Run Build.cmd first." -ForegroundColor Red 
  #   ExitWithExitCode 1
  # }
  #
  # for now just return the root folder containing the solution.
  $runTests = "test $($solution)"
  
  
  $dotnetExe = Join-Path $dotnet "dotnet.exe"
  #$args += " --dotnet `"$dotnetExe`""
  #$args += " --logs `"$LogDir`""
  $args += " --configuration $configuration"
  $args += " --no-build" # skip build, because netCore can't handle ComReferences.

  try {
    Write-Host "$runTests $args"
    #we need to build the Components solution via MSBuild because we use COM-Refernces.
    Run-MSBuild `"$projectFilePath`" -configuration $configuration -warnAsError:$false -treatWarningAsError:$false -buildArgs "/t:rebuild /p:NoWarn=1591"
    
    #call actual "Run Test" performed by netCore.
    Exec-Console $dotnetExe "$runTests $args"
  } finally {
    Get-Process "xunit*" -ErrorAction SilentlyContinue | Stop-Process
  }

  Write-Host "Tests finished" -ForegroundColor "Green"
}

  

  try {
    if ($PSVersionTable.PSVersion.Major -lt "5") {
      Write-Host "PowerShell version must be 5 or greater (version $($PSVersionTable.PSVersion) detected)"
      exit 1
    }
  
    $regKeyProperty = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name "LongPathsEnabled" -ErrorAction Ignore
    if (($null -eq $regKeyProperty) -or ($regKeyProperty.LongPathsEnabled -ne 1)) {
      Write-Host "LongPath is not enabled, you may experience build errors. You can avoid these by enabling LongPath with `"reg ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem /v LongPathsEnabled /t REG_DWORD /d 1`""
    }
  
    Process-Arguments
  
    . (Join-Path $PSScriptRoot "build-utils.ps1")
  
    Ensure-DotnetSdk
  
    Push-Location $RepoRoot
  
    # if ($ci) {
    #   List-Processes
    #   Prepare-TempDir

      
    if ($restore -or $build -or $rebuild -or $pack) {
      BuildSolution
    }
  
    try
    {
      if (<# $testWMSDetectionApp #> $testDesktop) {
        TestUsingRunTests
      }
    }
    catch
    {
      throw $_
    }
    
  
  
  
    ExitWithExitCode 0
  }
  catch {
    Write-Host $_
    Write-Host $_.Exception
    Write-Host $_.ScriptStackTrace
    ExitWithExitCode 1
  }
  finally {
    Pop-Location
  }