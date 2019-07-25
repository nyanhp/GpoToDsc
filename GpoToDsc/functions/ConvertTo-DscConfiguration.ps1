<#
.SYNOPSIS
    Generate DSC configuration from PolicyRules XML
.DESCRIPTION
    Convert all PolicyRules files in folder or merge them.

    To merge PolicyRules files, bring them in a naming pattern that can be treated with the split operator, e.g.
    <Department> - <OS> - <Version> - <Layer> - <Policyname>

    For example: SecOps - Windows - v3.1 - Baseline - Audit.PolicyRules

    The layer index after the split would be 3, so the cmdlet could be called thusly:

    ConvertTo-DscConfigurations -Path . -Pattern ' - ' -LayerIndex 3 -Precendence @(@('Baseline'), @('Baseline', 'DC'))

    The layers called Baseline and the merger of DC onto Baseline will be converted to DSC configurations

.PARAMETER Path
    Path to PolicyRules files
.PARAMETER Precedence
    The precedence of layers e.g.
    @('Baseline'), @('Baseline', 'DC')
.PARAMETER Pattern
    The pattern to split the basename of each policy export with
.PARAMETER LayerIndex
    At which index of the split basename is the name of the layer?
.PARAMETER SkipMerge
    Indicates that the precedence and layers should not be used. Instead, each individual file will be converted
    to a DSC configuration
.EXAMPLE
    .\ConvertTo-DscConfiguration.ps1 -Path D:\pol

    Without further parameter uses the split regex ' - ', the layer index 4 and the following precedence rules:
        @('Baseline'),
        @('Baseline', 'DC'),
        @('Baseline', 'Server'),
        @('Baseline', 'Client')
.EXAMPLE
    .\ConvertTo-DscConfiguration.ps1 -Path D:\pol -SkipMerge

    Converts each item to a DSC configuration.
#>
function ConvertTo-DscConfiguration
{
    [CmdletBinding(DefaultParameterSetName = 'Precedence')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [switch]
        $SkipMerge,

        [object[]]
        $Precedence = @(
            @('Baseline'),
            @('Baseline', 'DC'),
            @('Baseline', 'Server'),
            @('Baseline', 'Client')
        ),

        [string]
        $Pattern = ' - ',

        [uint16]
        $LayerIndex = 4
    )

    if ($SkipMerge)
    {
        $policyItems = Get-ChildItem -Path $Path -File -Filter *.PolicyRules | Get-ObjectFromPolicyRulesFile
        return $policyItems | Group-Object -Property PolicyName | ForEach-Object { $_.Group | Get-DscConfigurationString -ConfigurationName $_.Name }
    }

    # Group by layer
    $gpoFiles = Get-ChildItem -File -Path $Path | Group-Object { ($_.BaseName -split $Pattern)[$LayerIndex] } -AsHashTable -AsString

    foreach ($layer in $Precedence)
    {
        [string[]]$layer = $layer
        $exportName = $layer -join '-'

        foreach ($innerLayer in @($layer))
        {
            if (Get-Variable -Name "$($innerLayer)items" -ErrorAction SilentlyContinue) { continue }

            $policyItems = $gpoFiles.$innerLayer | Get-ObjectFromPolicyRulesFile
            $null = New-Variable -Name "$($innerLayer)items" -Value @{
                RegistryItems        = $policyItems.Where( { $_.ObjectType -eq 'RegistryItem' })
                UserRightsAssignment = $policyItems.Where( { $_.ObjectType -eq 'UserRightsAssignment' })
                SecurityOptions      = $policyItems.Where( { $_.ObjectType -eq 'SecurityOptions' })
                AuditPol             = $policyItems.Where( { $_.ObjectType -eq 'AuditPol' })
            }

            if ($layer[0] -ne $innerLayer)
            {
                $layer0Clone = Get-Variable -Name "$($layer[0])items"
                $var = Get-Variable -Name "$($innerLayer)items" -ValueOnly

                foreach ($item in $var.RegistryItems)
                {
                    $existingObject = $layer0Clone.Value.RegistryItems | Where-Object { $_.ValueName -eq $item.ValueName -and $_.Key -eq $item.Key }

                    if ($existingObject)
                    {
                        $existingObject.ValueData = $item.ValueData
                    }
                    else
                    {
                        $layer0Clone.Value.RegistryItems += $item
                    }
                }

                foreach ($uar in $var.UserRightsAssignment)
                {
                    $layer0Clone.Value.UserRightsAssignment = $layer0Clone.Value.UserRightsAssignment | Where-Object { $_.Policy -ne $uar.Policy }
                    $layer0Clone.Value.UserRightsAssignment += $uar
                }

                foreach ($aup in $var.AuditPol)
                {
                    $layer0Clone.Value.AuditPol = $layer0Clone.Value.AuditPol | Where-Object { $_.Name -ne $aup.Name -and $_.AuditFlag -ne $aup.AuditFlag }
                    $layer0Clone.Value.AuditPol += $aup
                }

                foreach ($secp in $var.SecurityOptions)
                {
                    $layer0Clone.Value.SecurityOptions = $layer0Clone.Value.SecurityOptions | Where-Object { $_.Name -ne $secp.SettingName }
                    $layer0Clone.Value.SecurityOptions += $secp
                }
            }
        }

        $layer0Clone = Get-Variable -Name "$($layer[0])items" -ValueOnly
        Get-DscConfigurationString -ConfigurationItem ($layer0Clone.RegistryItems + $layer0Clone.SecurityOptions + $layer0Clone.UserRightsAssignment + $layer0Clone.AuditPol) -ConfigurationName $exportName
    }
}
