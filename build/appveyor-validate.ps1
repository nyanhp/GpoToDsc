# Guide for available variables and working with secrets:
# https://docs.microsoft.com/en-us/vsts/build-release/concepts/definitions/build/variables?tabs=powershell

# Needs to ensure things are Done Right and only legal commits to master get built

# Run internal pester tests
& "$PSScriptRoot\..\GpoToDsc\tests\pester.ps1"
$testFiles = Get-Item -Path (Join-Path "$PSScriptRoot\..\TestResults" "TEST-*.xml")
foreach ($file in $testFiles)
{
    (New-Object 'System.Net.WebClient').UploadFile(
        "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
        "$file" )
}
