<#
.SYNOPSIS
    Convert array of policy rule entries to a DSC configuration script
.DESCRIPTION
    Convert array of policy rule entries to a DSC configuration script
.PARAMETER ConfigurationItem
    The list of configuration items
.PARAMETER ConfigurationName
    The name of the configuration
.EXAMPLE
    Get-ChildItem -Path . -File | Get-ObjectFromPolicyRulesFile | Group-Object -Property PolicyName | ForEach-Object { $_.Group | Get-DscConfigurationString -ConfigurationName $_.Name }
    
    Convert an entire folder of PolicyRules files to DSC configuration strings
#>
function Get-DscConfigurationString
{
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]
        $ConfigurationItem,

        [Parameter(Mandatory)]
        [string]
        $ConfigurationName
    )

    begin
    {
        $string = [System.Text.StringBuilder]::new()
        $null = $string.AppendLine( "configuration $($ConfigurationName)" )
        $null = $string.AppendLine( '{' )
        $null = $string.AppendLine( "     Import-DscResource -ModuleName PSDesiredStateConfiguration" )
        $null = $string.AppendLine( "     Import-DscResource -ModuleName SecurityPolicyDsc" )
        $null = $string.AppendLine( "     Import-DscResource -ModuleName AuditPolicyDsc" )
        $null = $string.AppendLine( '' )
        $null = $string.AppendLine( '' )
        $count = 0
    }

    process
    {
        
        foreach ($item in $ConfigurationItem)
        {
            Write-PSFMessage -Message ($item | Out-String)
            switch ($item.ObjectType)
            {
                'RegistryItem'
                {
                    $null = $string.AppendLine( "    $($item.ResourceName)" )
                    $null = $string.AppendLine( "     {" )
                    $null = $string.AppendLine( ("         ValueName = '{0}'" -f $item.ValueName))
                    $null = $string.AppendLine( ("         ValueData= '{0}'" -f $($item.ValueData -join '","')))
                    $null = $string.AppendLine( ("         ValueType = '{0}'" -f $Item.ValueType))
                    $null = $string.AppendLine( ("         Key = '{0}'" -f $Item.Key))
                    $null = $string.AppendLine( "     }" )
                    break
                }
                'UserRightsAssignment'
                {
                    $null = $string.AppendLine( "    $($item.ResourceName)" )
                    $null = $string.AppendLine( "     {" )
                    $null = $string.AppendLine( ("         Identity = '{0}'" -f $($item.Identity -join "','")))
                    $null = $string.AppendLine( ("         Policy = '{0}'" -f $item.Policy))
                    $null = $string.AppendLine( "     }" )
                    break
                }
                'SecurityOptions'
                {
                    $null = $string.AppendLine( "    $($item.ResourceName)" )
                    $null = $string.AppendLine( "     {" )
                    $null = $string.AppendLine( "        $($item.SettingName) = '$($item.SettingValue)'")
                    $null = $string.AppendLine( "        Name = '$($item.ObjectType)$count'")
                    $null = $string.AppendLine( "     }" )
                    $count ++
                    break
                }
                'AuditPol'
                {
                    $null = $string.AppendLine( "    $($item.ResourceName)" )
                    $null = $string.AppendLine( "     {" )
                    $null = $string.AppendLine( ("         AuditFlag = '{0}'" -f $item.AuditFlag))
                    $null = $string.AppendLine( ("         Name = '{0}'" -f $item.Name))
                    $null = $string.AppendLine( "     }" )
                    break
                }
            }
            
            $null = $string.AppendLine( '' )
            $null = $string.AppendLine( '' )
        }
    }

    end
    {
        $null = $string.AppendLine( '}' )
        $string.ToString()
    }
}
