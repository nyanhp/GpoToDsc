# GPO to DSC

This little module enables a conversion from GPO exports in the PolicyRules format to DSC configurations.

## Installation

```powershell
Install-Module GpoToDsc
```

## Usage

1. Download and familiarize yourself with the Microsoft Security Compliance Toolkit 1.0 from <https://www.microsoft.com/en-us/download/details.aspx?id=55319>
1. Create some PolicyRules files for the policies you would like to convert
1. Enjoy!

After you have generated the necessary policies, usage is simple:

```powershell
ConvertTo-DscConfiguration -Path ./Policies -SkipMerge | Export-DscConfiguration -Path D:\temp
```  

After which n PowerShell scripts as well as n MOF files will have been created. You could use these with
DSCEA or Test-DscConfiguration. Or if you are confident you can apply them to any environment...
