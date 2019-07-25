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
    ConvertTo-DscConfiguration -Path ./blorb -SkipMerge | Export-DscConfiguration -Path ./export -Force

    Converts a bunch of PolicyRules files to DSC code and exports all configurations and their MOFs
#>
function Export-DscConfiguration
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
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
    }
    
    process
    {
        if (-not (Test-Path $Path))
        {
            Write-PSFMessage "Skipping configuration because $Path is not present and -Force has not been used."
            break
        }
        
        $configurationScript = [scriptblock]::Create($Configuration)
        $configurationName = $configurationScript.Ast.FindAll( { $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true).InstanceName
        
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
