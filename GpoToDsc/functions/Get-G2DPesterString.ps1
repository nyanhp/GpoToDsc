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
        Write-PSFMessage -Message ($ConfigurationItem | Out-String)
        switch ($ConfigurationItem.ObjectType)
        {
            'RegistryItem'
            {
                $null = $string.AppendLine( ("    It 'Registry entry - `"{0}\{1}`" should have value {2}' {3}" -f $ConfigurationItem.Key, $ConfigurationItem.ValueName, $ConfigurationItem.ValueData, '{'))
                $vData = if ($ConfigurationItem.ValueData.Count -gt 1)
                {
                    '@("{0}")' -f $($ConfigurationItem.ValueData -join '","')
                }
                elseif ($ConfigurationItem.ValueData.Count -eq 1)
                {
                    $ConfigurationItem.ValueData
                }
                else
                {
                    "`$null"
                }
                $null = $string.AppendLine( ("(Get-ItemProperty -Path '{0}' -Name '{1}' -ErrorAction SilentlyContinue).'{1}' | Should -Be {2}" -f ($ConfigurationItem.Key -replace 'HKEY_LOCAL_MACHINE', 'HKLM:' -replace 'HKEY_CURRENT_USER', 'HKCU:'), $ConfigurationItem.ValueName, $vData))
                $null = $string.AppendLine( "     }" )
                break
            }
            'UserRightsAssignment'
            {
                $null = $string.AppendLine( ("It 'User Rights Assignment - Identity `"{0}`" should be configured for/to do {1}' {2}" -f ($ConfigurationItem.Identity -join ','), $ConfigurationItem.Policy, '{') )
                $null = $string.AppendLine( "     Invoke-DscResource -Name UserRightsAssignment -Module SecurityPolicyDsc -Method Test -Prop @{" )
                $null = $string.AppendLine( ("         Identity = '{0}'" -f $($ConfigurationItem.Identity -join "','")))
                $null = $string.AppendLine( ("         Policy = '{0}'" -f $ConfigurationItem.Policy))
                $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true }" )
                break
            }
            'SecurityOptions'
            {
                $null = $string.AppendLine( ("It 'Security Option - {0} should be {1}' {2}" -f $ConfigurationItem.SettingName, $ConfigurationItem.SettingValue, '{') )
                $null = $string.AppendLine( "Invoke-DscResource -Name SecurityOption -Method Test -Module SecurityPolicyDsc -Prop @{" )
                $null = $string.AppendLine( "        $($ConfigurationItem.SettingName) = '$($ConfigurationItem.SettingValue)'")
                $null = $string.AppendLine( "        Name = '$($ConfigurationItem.ObjectType)$count'")
                $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true } " )
                $count ++
                break
            }
            'AuditPol'
            {
                $null = $string.AppendLine( ("It 'Audit Setting - `"{0}`" should be configured to audit `"{1}`"' {2}" -f $ConfigurationItem.Name, $ConfigurationItem.AuditFlag, '{') )
                $null = $string.AppendLine( "Invoke-DscResource -Name AuditPolicy -Module AuditPolicyDsc -Method Test -Prop @{" )
                $null = $string.AppendLine( ("         AuditFlag = '{0}'" -f $ConfigurationItem.AuditFlag))
                $null = $string.AppendLine( ("         Name = '{0}'" -f $ConfigurationItem.Name))
                $null = $string.AppendLine( "     } -ErrorAction SilentlyContinue | Should -Be `$true }" )
                break
            }
        }
            
        $null = $string.AppendLine( '' )
        $null = $string.AppendLine( '' )
    }

    end
    {
        $null = $string.AppendLine( '}' )
        $string.ToString()
    }
}
