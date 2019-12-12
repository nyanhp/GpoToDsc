﻿<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey = $env:nugetapikey,

	$WorkingDirectory = $env:APPVEYOR_BUILD_FOLDER
)

# Prepare publish folder
Write-PSFMessage -Level Important -Message "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory
Copy-Item -Path "$($WorkingDirectory)\GpoToDsc" -Destination $publishDir.FullName -Recurse -Force

#region Gather text data to compile
$text = @()
$processed = @()

# Gather Stuff to run before
foreach ($line in (Get-Content "$($PSScriptRoot)\filesBefore.txt" | Where-Object { $_ -notlike "#*" }))
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }

	$basePath = Join-Path "$($publishDir.FullName)\GpoToDsc" $line
	foreach ($entry in (Resolve-PSFPath -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\GpoToDsc\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\GpoToDsc\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather stuff to run afterwards
foreach ($line in (Get-Content "$($PSScriptRoot)\filesAfter.txt" | Where-Object { $_ -notlike "#*" }))
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }

	$basePath = Join-Path "$($publishDir.FullName)\GpoToDsc" $line
	foreach ($entry in (Resolve-PSFPath -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}
#endregion Gather text data to compile

# Compile library
mkdir -force "$($publishDir.FullName)\GpoToDsc\library"
Add-Type -TypeDefinition @'
public class ValidationItem
{
    string ValidationString {get; set;}
    string ConfigurationName {get; set;}
    string ValidationType {get; set;}

    ValidationItem (string valString, string confName, string valType)
    {
        ValidationString = valString;
        ConfigurationName = confName;
        ValidationType = valType;
    }

    public override string ToString()
    {
        return ValidationString;
    }
}
'@ -OutputAssembly "$($publishDir.FullName)\GpoToDsc\library\lib.dll"

#region Update the psm1 file
$fileData = Get-Content -Path "$($publishDir.FullName)\GpoToDsc\GpoToDsc.psm1" -Raw
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\GpoToDsc\GpoToDsc.psm1", $fileData, [System.Text.Encoding]::UTF8)
#endregion Update the psm1 file

# Publish to Gallery
if ($env:APPVEYOR_REPO_BRANCH -eq 'master' -and [string]::IsNullOrWhiteSpace($env:APPVEYOR_PULL_REQUEST_NUMBER))
{
	Publish-Module -Path "$($publishDir.FullName)\GpoToDsc" -NuGetApiKey $ApiKey -Force
}
