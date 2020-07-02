<#
.SYNOPSIS
    Export a pester string to a PS1 file
.DESCRIPTION
    Export a pester string to a PS1 file
.PARAMETER Path
    Path to export
.PARAMETER Configuration
    The string containing one configuration
.PARAMETER Force
    Indicates that you are a Jedi
.PARAMETER WhatIf
    Indicates that you want to try the cmdlet without any changes
.PARAMETER Confirm
    Indicates that you want a confirmation before anything bad happens.
.EXAMPLE
    ConvertTo-G2DValidation -Path ./blorb -SkipMerge | Export-G2DPesterSuite -Path ./export -Force

    Converts a bunch of PolicyRules files to Pester tests and exports all test suites as separate files
#>
function Export-G2DPesterSuite
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidationItem]
        $Configuration,

        [switch]
        $Force
    )

    begin
    {
        if (-not (Test-Path $Path) -and $Force.IsPresent -and $PSCmdlet.ShouldProcess($Path, 'Create Pester test directory'))
        {
            $null = New-Item -ItemType Directory -Path $Path -Force
        }

        if (-not (Test-Path $Path))
        {
            Stop-PSFFunction -Message "Skipping Pester export because $Path is not present and -Force has not been used." -EnableException $true
        }
    }
    
    process
    {
        if ($Configuration.ValidationType -ne 'Pester')
        {
            Write-PSFMessage "Skipping configuration because $($Configuration.ConfigurationName) is not of type Pester"
            return
        }

        if ($PSCmdlet.ShouldProcess($Configuration.ConfigurationName, 'Export validation'))
        {
            $scriptName = Join-Path -Path $Path -ChildPath "$($Configuration.ConfigurationName).tests.ps1"
            $Configuration | Set-Content -Path $scriptName
            Get-Item -Path $scriptName
        }
    }
}
