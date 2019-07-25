<#
.SYNOPSIS
    Convert PolicyRules XML content to objects
.DESCRIPTION
    Convert PolicyRules XML content to objects
.PARAMETER Path
    The full file path to each files
.EXAMPLE
    Get-ChildItem | Get-ObjectFromPolicyRulesFile

    Gets a bunch of objects contained in PolicyRules files
#>
function Get-ObjectFromPolicyRulesFile
{
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]
        $Path
    )

    process
    {
        foreach ($file in $Path)
        {
            [xml]$content = Get-Content -Path $file -Encoding UTF8
            $policyName = [IO.Path]::GetFileNameWithoutExtension($file)

            #region Registry settings
            foreach ( $line in $content.SelectNodes('/PolicyRules/SecurityTemplate[@Section = "Registry Values"]/LineItem').InnerText)
            {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }

                $split1 = $line -split '='
                $valueType = [Microsoft.Win32.RegistryValueKind]($split1[-1] -split ',')[0]

                if ($split1[-1] -match ',"+')
                {
                    $split2 = $split1[-1] -split '[^"],' -replace '"'
                }
                else
                {
                    $split2 = $split1[-1] -split ','
                }
                
                if ([string]::IsNullOrWhiteSpace($split2[-1])) { continue }
                if ($split2[0] -eq 7) { continue }

                $valueData = $split2 | Select-Object -Skip 1
                if ($valueData -eq '\0')
                {
                    $valueData = [string]::Empty
                }
                elseif ($valueData -like '*\0')
                {
                    $valueData = $valueData -split '\\0'
                }

                [PSCustomObject]@{
                    ResourceName = "Registry '$($policyName)_$(Split-Path -Leaf -Path $split1[0])_$((New-Guid).Guid)'"
                    Key          = $('HKEY_LOCAL_{0}' -f (Split-Path -Parent -Path $split1[0]))
                    ValueName    = $(Split-Path -Leaf -Path $split1[0])
                    ValueData    = $valueData
                    ValueType    = $valueType
                    ObjectType   = 'RegistryItem'
                    PolicyName   = $policyName
                }
            }

            foreach ($item in $content.SelectNodes('/PolicyRules/ComputerConfig'))
            {
                $valueData = $item.RegData

                if ($valueData -eq '\0')
                {
                    $valueData = [string]::Empty
                }
                elseif ($valueData -like '*\0*')
                {
                    $valueData = $valueData -split '\\0'
                }

                $valueType = switch ($item.RegType)
                {
                    'REG_DWORD' { 'Dword' }
                    'REG_QWORD' { 'Qword' }
                    'REG_MULTI_SZ' { 'Multistring' }
                    'REG_SZ' { 'String' }
                    'REG_BINARY' { 'Binary' }
                    'REG_EXPAND_SZ' { 'ExpandedString' }
                }

                [PSCustomObject]@{
                    ResourceName = "Registry '$($policyName)_$($item.Value)_$((New-Guid).Guid)'"
                    Key          = "HKEY_LOCAL_MACHINE\$($item.Key)"
                    ValueName    = "$($item.Value)"
                    ValueData    = $valueData
                    ValueType    = "$($valueType)"
                    ObjectType   = 'RegistryItem'
                    PolicyName   = $policyName
                }
            }
            #endregion

            #region User Rights Assignments
            foreach ( $item in $content.SelectNodes('/PolicyRules/SecurityTemplate[@Section = "Privilege Rights"]/LineItem').InnerText)
            {
                $tokenKind = $sids = $null
                $tokenKind, $sids = $item -split '='
                if ([string]::IsNullOrWhiteSpace($sids) -or ($sids -split ',').Count -eq 0) { continue }
                $translatedToken = $mapping[$tokenKind]

                if ($null -eq $translatedToken)
                {
                    Write-PSFMessage -Level Warning -Message "Could not translate $tokenKind"
                    continue
                }

                [PSCustomObject]@{
                    Policy       = $translatedToken
                    Identity     = $sids -split ','
                    ResourceName = "UserRightsAssignment '$($policyName)_$($tokenKind)_$((New-Guid).Guid)'"
                    ObjectType   = 'UserRightsAssignment'
                    PolicyName   = $policyName
                }
            }
            #endregion

            #region AuditPol
            foreach ( $item in $content.SelectNodes('/PolicyRules/AuditSubcategory'))
            {
                if ([string]::IsNullOrWhiteSpace($item.Setting)) { continue }
                $name = $item.Name -replace '^Audit '
                $flag = ([System.Security.AccessControl.AuditFlags][int]$item.Setting).ToString() -replace ',', ' And' -replace 'None', 'No Auditing'
                [PSCustomObject]@{
                    ResourceName = "AuditPolicyGUID '$($policyName)_$($name)-$($flag)_$((New-Guid).Guid)'"
                    AuditFlag    = $flag
                    Name         = $name
                    ObjectType   = 'AuditPol'
                    PolicyName   = $policyName
                }
            }
            #endregion

            #region System access
            foreach ( $item in $content.SelectNodes('/PolicyRules/SecurityTemplate[@Section = "System Access"]/LineItem').InnerText)
            {
                $setting, $settingvalue = $item -split '='

                switch ($setting)
                {
                    NewGuestName
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue -replace '"' -replace "'"
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }
                        
                        break
                    }
                    LSAAnonymousNameLookup
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    EnableGuestAccount
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    NewAdministratorName
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue -replace '"' -replace "'"
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    EnableAdminAccount
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    ForceLogoffWhenHourExpire
                    {
                        [PSCustomObject]@{
                            ResourceName = "SecurityOption '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MinimumPasswordLength
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MaxTicketAge
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MinimumPasswordAge
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    LockoutDuration
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MaxClockSkew
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    LockoutBadCount
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MaximumPasswordAge
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MaxRenewAge
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    MaxServiceAge
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    PasswordComplexity
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    ClearTextPassword
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    TicketValidateClient
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    ResetLockoutCount
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = if ( $settingValue -eq 0) { "Disabled" } else { "Enabled" }
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    PasswordHistorySize
                    {
                        [PSCustomObject]@{
                            ResourceName = "AccountPolicy '$($policyName)_$($setting)_$((New-Guid).Guid)'"
                            SettingName  = $mapping[$setting]
                            SettingValue = $settingvalue
                            ObjectType   = 'SecurityOptions'
                            PolicyName   = $policyName
                        }

                        break
                    }
                    default { Write-PSFMessage -Level Warning -Message "Could not guess policy for setting $setting with value $settingvalue. Please examine the output of 'Get-DscResource -Syntax -Name SecurityOption'." }
                }

            }

            #endregion
        }
    }
}
