$modules = @("Pester", "PSFramework", "PSScriptAnalyzer", 'PSModuleDevelopment')

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
    public string ValidationString {get; set;}
    public string ConfigurationName {get; set;}
    public string ValidationType {get; set;}

    public ValidationItem (string valString, string confName, string valType)
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
'@ -OutputAssembly "$PSScriptRoot\..\GpoToDsc\library\gpotodsc.dll"