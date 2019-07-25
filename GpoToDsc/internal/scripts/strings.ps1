Import-PSFLocalizedString -Path "$script:ModuleRoot\en-us\*.psd1" -Module GpoToDsc -Language 'en-US'

$script:mapping = Get-PSFLocalizedString -Module GpoToDsc