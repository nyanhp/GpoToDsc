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
    Get-ChildItem -Path . -File | Get-G2DObjectFromPolicyRulesFile | Group-Object -Property PolicyName | ForEach-Object { $_.Group | Get-G2DDscConfigurationString -ConfigurationName $_.Name }
    
    Convert an entire folder of PolicyRules files to DSC configuration strings
#>
function Get-G2DPesterString
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
        $null = $string.AppendLine( "#Requires -Module @{ ModuleName = 'Pester'; RequiredVersion = '4.9.0' }" )
        $null = $string.AppendLine( "Describe 'Testing policy $($ConfigurationName)' {" )
        $null = $string.AppendLine( '' )
        $null = $string.AppendLine( '' )
        $count = 0
    }

    process
    {
        $groups = $ConfigurationItem | Group-Object -Property PolicyName
        foreach ($group in $groups)
        {
            $null = $string.AppendLine("Context '$($group.Name)' {")

            foreach ($item in $group.Group)
            {
                Write-PSFMessage -Message ($item | Out-String)
                switch ($item.ObjectType)
                {
                    'RegistryItem'
                    {
                        $null = $string.AppendLine( ("    It 'Registry entry - `"{0}\{1}`" should have value {2}' {3}" -f $item.Key, $item.ValueName, $item.ValueData, '{'))
                        $vData = if ($item.ValueData.Count -gt 1)
                        {
                            '@("{0}")' -f $($item.ValueData -join '","')
                        }
                        elseif ($item.ValueData.Count -eq 1)
                        {
                            $item.ValueData
                        }
                        else
                        {
                            "`$null"
                        }
                        $null = $string.AppendLine( ("(Get-ItemProperty -Path '{0}' -Name '{1}' -ErrorAction SilentlyContinue).'{1}' | Should -Be {2}" -f ($Item.Key -replace 'HKEY_LOCAL_MACHINE', 'HKLM:' -replace 'HKEY_CURRENT_USER','HKCU:'), $item.ValueName, $vData))
                        $null = $string.AppendLine( "     }" )
                        break
                    }
                    'UserRightsAssignment'
                    {
                        $null = $string.AppendLine( ("It 'User Rights Assignment - Identity `"{0}`" should be configured for/to do {1}' {2}" -f ($item.Identity -join ','), $item.Policy, '{') )
                        $null = $string.AppendLine( "     Invoke-DscResource -Name UserRightsAssignment -Module SecurityPolicyDsc -Method Test -Prop @{" )
                        $null = $string.AppendLine( ("         Identity = '{0}'" -f $($item.Identity -join "','")))
                        $null = $string.AppendLine( ("         Policy = '{0}'" -f $item.Policy))
                        $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true }" )
                        break
                    }
                    'SecurityOptions'
                    {
                        $null = $string.AppendLine( ("It 'Security Option - {0} should be {1}' {2}" -f $item.SettingName, $item.SettingValue, '{') )
                        $null = $string.AppendLine( "Invoke-DscResource -Name SecurityOption -Method Test -Module SecurityPolicyDsc -Prop @{" )
                        $null = $string.AppendLine( "        $($item.SettingName) = '$($item.SettingValue)'")
                        $null = $string.AppendLine( "        Name = '$($item.ObjectType)$count'")
                        $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true } " )
                        $count ++
                        break
                    }
                    'AuditPol'
                    {
                        $null = $string.AppendLine( ("It 'Audit Setting - `"{0}`" should be configured to audit `"{1}`"' {2}" -f $Item.Name, $Item.AuditFlag, '{') )
                        $null = $string.AppendLine( "Invoke-DscResource -Name AuditPolicy -Module AuditPolicyDsc -Method Test -Prop @{" )
                        $null = $string.AppendLine( ("         AuditFlag = '{0}'" -f $item.AuditFlag))
                        $null = $string.AppendLine( ("         Name = '{0}'" -f $item.Name))
                        $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true }" )
                        break
                    }
                }
            
                $null = $string.AppendLine( '' )
                $null = $string.AppendLine( '' )
            }
            $null = $string.AppendLine( '}' )
        }
    }

    end
    {
        $null = $string.AppendLine( '}' )
        $string.ToString()
    }
}
