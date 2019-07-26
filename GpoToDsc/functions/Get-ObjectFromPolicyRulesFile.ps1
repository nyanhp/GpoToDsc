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
            $resultList = [System.Collections.ArrayList]::new()
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

                $regKey = $('HKEY_LOCAL_{0}' -f (Split-Path -Parent -Path $split1[0]))

                $result = [PSCustomObject]@{
                    ResourceName = "Registry '$($policyName)_$(Split-Path -Leaf -Path $split1[0])_$((New-Guid).Guid)'"
                    Key          = $regKey
                    ValueName    = $(Split-Path -Leaf -Path $split1[0])
                    ValueData    = $valueData
                    ValueType    = $valueType
                    ObjectType   = 'RegistryItem'
                    PolicyName   = $policyName
                }

                $existingItem = $resultList | Where-Object -FilterScript { $_.ObjectType -eq 'RegistryItem' -and $_.Key -eq $regKey }

                if ($null -ne $existingItem)
                {
                    $existingItem = $result
                    continue
                }
                
                $null = $resultList.Add($result)
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
                    'REG_DWORD' { 'Dword'; break }
                    'REG_QWORD' { 'Qword'; break }
                    'REG_MULTI_SZ' { 'Multistring'; break }
                    'REG_SZ' { 'String'; break }
                    'REG_BINARY' { 'Binary'; break }
                    'REG_EXPAND_SZ' { 'ExpandString'; break }
                    default { Write-PSFMessage -Level Warning -Message "Skipping HKEY_LOCAL_MACHINE\$($item.Key) as it is REG_NONE" }
                }

                if ($null -eq $valueType)
                {
                    continue
                }

                $regKey = "HKEY_LOCAL_MACHINE\$($item.Key)"

                $result = [PSCustomObject]@{
                    ResourceName = "Registry '$($policyName)_$($item.Value)_$((New-Guid).Guid)'"
                    Key          = "HKEY_LOCAL_MACHINE\$($item.Key)"
                    ValueName    = "$($item.Value)"
                    ValueData    = $valueData
                    ValueType    = "$($valueType)"
                    ObjectType   = 'RegistryItem'
                    PolicyName   = $policyName
                }

                $existingItem = $resultList | Where-Object -FilterScript { $_.ObjectType -eq 'RegistryItem' -and $_.Key -eq $regKey }

                if ($null -ne $existingItem)
                {
                    $existingItem = $result
                    continue
                }
                
                $null = $resultList.Add($result)
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

                $result = [PSCustomObject]@{
                    Policy       = $translatedToken
                    Identity     = $sids -split ','
                    ResourceName = "UserRightsAssignment '$($policyName)_$($tokenKind)_$((New-Guid).Guid)'"
                    ObjectType   = 'UserRightsAssignment'
                    PolicyName   = $policyName
                }

                $existingItem = $resultList | Where-Object -FilterScript { $_.ObjectType -eq 'UserRightsAssignment' -and $_.Policy -eq $translatedToken }

                if ($null -ne $existingItem)
                {
                    $existingItem = $result
                    continue
                }
                
                $null = $resultList.Add($result)
            }
            #endregion

            #region AuditPol
            foreach ( $item in $content.SelectNodes('/PolicyRules/AuditSubcategory'))
            {
                if ([string]::IsNullOrWhiteSpace($item.Setting)) { continue }
                $name = $item.Name -replace '^Audit '
                $flag = ([System.Security.AccessControl.AuditFlags][int]$item.Setting).ToString() -replace ',', ' And' -replace 'None', 'No Auditing'

                # Due to a very questionable design choice in AuditPolicyDsc, we have
                # to replace two real policy names with some made-up names that someone deemed fitting
                # Name in gpedit.msc and exports: PNP Activity vs made-up name Plug and Play Events
                # Name in gpedit.msc and exports: Token Right Adjusted vs made-up name Token Right Adjusted Events
                if ($name -eq 'PNP Activity')
                {
                    $name = 'Plug and Play Events'
                }
                elseif ($name -eq 'Token Right Adjusted')
                {
                    $name = 'Token Right Adjusted Events'
                }
                
                $result = [PSCustomObject]@{
                    ResourceName = "AuditPolicyGUID '$($policyName)_$($name)-$($flag)_$((New-Guid).Guid)'"
                    AuditFlag    = $flag
                    Name         = $name
                    ObjectType   = 'AuditPol'
                    PolicyName   = $policyName
                }

                $existingItem = $resultList | Where-Object -FilterScript { $_.ObjectType -eq 'AuditPol' -and ($_.Name -eq $name -and $_.AuditFlag -eq $flag) }

                if ($null -ne $existingItem)
                {
                    $existingItem = $result
                    continue
                }
                
                $null = $resultList.Add($result)
            }
            #endregion

            #region System access
            foreach ( $item in $content.SelectNodes('/PolicyRules/SecurityTemplate[@Section = "System Access"]/LineItem').InnerText)
            {
                $setting, $settingvalue = $item -split '='

                $result = switch ($setting)
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
                            SettingValue = $settingValue
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

                if ($null -ne $result)
                {
                    $null = $resultList.Add($result)
                }
            }
            #endregion
        }
        
        $resultList
    }
}
