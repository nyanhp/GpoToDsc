$modules = @("Pester", "PSFramework", "PSScriptAnalyzer")

foreach ($module in $modules) {
    Write-Host "Installing $module" -ForegroundColor Cyan
    Install-Module $module -Force -SkipPublisherCheck
    Import-Module $module -Force -PassThru
}


# Compile library
mkdir -force "$PSScriptRoot\..\GpoToDsc\library"
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
'@ -OutputAssembly "$PSScriptRoot\..\GpoToDsc\library\lib.dll"