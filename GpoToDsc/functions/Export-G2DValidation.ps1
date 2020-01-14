<#
.SYNOPSIS
    Export a configuration string to a PS1 file and build a MOF
.DESCRIPTION
    Export a configuration string to a PS1 file and build a MOF
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
    ConvertTo-G2DValidation -Path ./blorb -SkipMerge | Export-G2DConfiguration -Path ./export -Force

    Converts a bunch of PolicyRules files to DSC code and exports all configurations and their MOFs
#>
function Export-G2DValidation
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
        if (-not (Test-Path $Path) -and $Force.IsPresent -and $PSCmdlet.ShouldProcess($Path, 'Create MOF directory'))
        {
            $null = New-Item -ItemType Directory -Path $Path -Force
        }

        if (-not (Test-Path $Path))
        {
            Stop-PSFFunction -Message "Skipping MOF export because $Path is not present and -Force has not been used." -EnableException $true
        }
    }
    
    process
    {
        if ($Configuration.ValidationType -ne 'Dsc')
        {
            Write-PSFMessage "Skipping configuration because $($Configuration.ConfigurationName) is not of type DSC"
            return
        }
        
        $configurationScript = [scriptblock]::Create($Configuration.ToString())
        $configurationName = $Configuration.ConfigurationName
        
        if ($PSCmdlet.ShouldProcess($configurationName, 'Export configuration and compile MOF'))
        {
            . $configurationScript
            $scriptName = Join-Path -Path $Path -ChildPath "$($configurationName).ps1"
            $Configuration | Set-Content -Path $scriptName

            if (((Get-Module -ListAvailable SecurityPolicyDsc,AuditPolicyDsc).Name | Sort-Object -Unique).Count -lt 2)
            {
                Write-PSFMessage -Level Warning -Message "Modules SecurityPolicyDsc and AuditPolicyDsc are not available. Skipping MOF production."
                continue
            }
            & $configurationName -OutputPath (Join-Path -Path $Path -ChildPath $configurationName)
        }
    }
}
