# Place all code that should be run before functions are imported here

# Load the strings used in messages
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\strings.ps1"

class ValidationItem
{
    [string] $ValidationString
    [string] $ConfigurationName
    [string] $ValidationType

    ValidationItem ([string] $valString, [string] $confName, [string] $valType)
    {
        $this.ValidationString = $valString
        $this.ConfigurationName = $confName
        $this.ValidationType = $valType
    }

    [string] ToString()
    {
        return $this.ValidationString
    }
}