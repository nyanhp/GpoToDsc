@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess   = 'GpoToDsc.psm1'
	
    # Version number of this module.
    ModuleVersion     = '1.0.0'
	
    # ID used to uniquely identify this module
    GUID              = '13049ea4-96d6-4ab1-91c6-7c895c2ae66f'
	
    # Author of this module
    Author            = 'Jan-Hendrik Peters'
	
    # Company or vendor of this module
    CompanyName       = 'Jan-Hendrik Peters'
	
    # Copyright statement for this module
    Copyright         = 'Copyright (c) 2019 Jan-Hendrik Peters'
	
    # Description of the functionality provided by this module
    Description       = 'Helper module to do some Group Policy to Desired State Configuration conversion'
	
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'
	
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(@{ ModuleName = 'PSFramework'; ModuleVersion = '1.0.19' })
	
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @('bin\GpoToDsc.dll')
	
    # Type files (.ps1xml) to be loaded when importing this module
    # Expensive for import time, no more than one should be used.
    # TypesToProcess = @('xml\GpoToDsc.Types.ps1xml')
	
    # Format files (.ps1xml) to be loaded when importing this module.
    # Expensive for import time, no more than one should be used.
    # FormatsToProcess = @('xml\GpoToDsc.Format.ps1xml')
	
    # Functions to export from this module
    FunctionsToExport = 'Export-DscConfiguration', 'Get-ObjectFromPolicyRulesFile', 'Get-DscConfigurationString', 'ConvertTo-DscConfiguration'
	
    # Cmdlets to export from this module
    CmdletsToExport   = ''
	
    # Variables to export from this module
    VariablesToExport = ''
	
    # Aliases to export from this module
    AliasesToExport   = ''
	
    # List of all files packaged with this module
    FileList          = @()
	
    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
		
        #Support for PowerShellGet galleries.
        PSData = @{
			
            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()
			
            # A URL to the license for this module.
            # LicenseUri = ''
			
            # A URL to the main website for this project.
            # ProjectUri = ''
			
            # A URL to an icon representing this module.
            # IconUri = ''
			
            # ReleaseNotes of this module
            # ReleaseNotes = ''
			
        } # End of PSData hashtable
		
    } # End of PrivateData hashtable
}