<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'GpoToDsc' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'GpoToDsc' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'GpoToDsc' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."
Set-PSFConfig -Module 'GpoToDsc' -Name 'AuditPolMapping' -Value @{
    SeLoadDriverPrivilege                     = 'Load_and_unload_device_drivers'
    SeImpersonatePrivilege                    = 'Impersonate_a_client_after_authentication'
    SeDelegateSessionUserImpersonatePrivilege = 'Obtain_an_impersonation_token_for_another_user_in_the_same_session'
    SeShutdownPrivilege                       = 'Shut_down_the_system'
    SeTakeOwnershipPrivilege                  = 'Take_ownership_of_files_or_other_objects'
    SeDenyInteractiveLogonRight               = 'Deny_log_on_locally'
    SeDenyBatchLogonRight                     = 'Deny_log_on_as_a_batch_job'
    SeRemoteInteractiveLogonRight             = 'Allow_log_on_through_Remote_Desktop_Services'
    SeRelabelPrivilege                        = 'Modify_an_object_label'
    SeCreateSymbolicLinkPrivilege             = 'Create_symbolic_links'
    SeSystemtimePrivilege                     = 'Change_the_system_time'
    SeDebugPrivilege                          = 'Debug_programs'
    SeDenyRemoteInteractiveLogonRight         = 'Deny_log_on_through_Remote_Desktop_Services'
    SeServiceLogonRight                       = 'Log_on_as_a_service'
    SeIncreaseWorkingSetPrivilege             = 'Increase_a_process_working_set'
    SeTcbPrivilege                            = 'Act_as_part_of_the_operating_system'
    SeIncreaseBasePriorityPrivilege           = 'Increase_scheduling_priority'
    SeUndockPrivilege                         = 'Remove_computer_from_docking_station'
    SeBatchLogonRight                         = 'Log_on_as_a_batch_job'
    SeTimeZonePrivilege                       = 'Change_the_time_zone'
    SeSystemEnvironmentPrivilege              = 'Modify_firmware_environment_values'
    SeProfileSingleProcessPrivilege           = 'Profile_single_process'
    SeAssignPrimaryTokenPrivilege             = 'Replace_a_process_level_token'
    SeInteractiveLogonRight                   = 'Allow_log_on_locally'
    SeCreatePagefilePrivilege                 = 'Create_a_pagefile'
    SeRestorePrivilege                        = 'Restore_files_and_directories'
    SeCreateTokenPrivilege                    = 'Create_a_token_object'
    SeCreatePermanentPrivilege                = 'Create_permanent_shared_objects'
    SeSystemProfilePrivilege                  = 'Profile_system_performance'
    SeCreateGlobalPrivilege                   = 'Create_global_objects'
    SeSyncAgentPrivilege                      = 'Synchronize_directory_service_data'
    SeIncreaseQuotaPrivilege                  = 'Adjust_memory_quotas_for_a_process'
    SeDenyServiceLogonRight                   = 'Deny_log_on_as_a_service'
    SeDenyNetworkLogonRight                   = 'Deny_access_to_this_computer_from_the_network'
    SeEnableDelegationPrivilege               = 'Enable_computer_and_user_accounts_to_be_trusted_for_delegation'
    SeRemoteShutdownPrivilege                 = 'Force_shutdown_from_a_remote_system'
    SeNetworkLogonRight                       = 'Access_this_computer_from_the_network'
    SeManageVolumePrivilege                   = 'Perform_volume_maintenance_tasks'
    SeSecurityPrivilege                       = 'Manage_auditing_and_security_log'
    SeAuditPrivilege                          = 'Generate_security_audits'
    SeLockMemoryPrivilege                     = 'Lock_pages_in_memory'
    SeTrustedCredManAccessPrivilege           = 'Access_Credential_Manager_as_a_trusted_caller'
    SeBackupPrivilege                         = 'Back_up_files_and_directories'
    SeMachineAccountPrivilege                 = 'Add_workstations_to_domain'
    SeChangeNotifyPrivilege                   = 'Bypass_traverse_checking'
    MinimumPasswordLength                     = 'Minimum_Password_Length'
    MaxTicketAge                              = 'Maximum_lifetime_for_user_ticket'
    MinimumPasswordAge                        = 'Minimum_Password_Age'
    LockoutDuration                           = 'Account_lockout_duration'
    MaxClockSkew                              = 'Maximum_tolerance_for_computer_clock_synchronization'
    LockoutBadCount                           = 'Account_lockout_threshold'
    MaximumPasswordAge                        = 'Maximum_Password_Age'
    MaxRenewAge                               = 'Maximum_lifetime_for_user_ticket_renewal'
    MaxServiceAge                             = 'Maximum_lifetime_for_service_ticket'
    PasswordComplexity                        = 'Password_must_meet_complexity_requirements'
    ClearTextPassword                         = 'Store_passwords_using_reversible_encryption'
    TicketValidateClient                      = 'Enforce_user_logon_restrictions'
    ResetLockoutCount                         = 'Reset_account_lockout_counter_after'
    PasswordHistorySize                       = 'Enforce_password_history'
    NewGuestName                              = 'Accounts_Rename_guest_account'
    LSAAnonymousNameLookup                    = 'Network_access_Allow_anonymous_SID_Name_translation'
    EnableGuestAccount                        = 'Accounts_Guest_account_status'
    NewAdministratorName                      = 'Accounts_Rename_administrator_account'
    EnableAdminAccount                        = 'Accounts_Administrator_account_status'
    ForceLogoffWhenHourExpire                 = 'Network_security_Force_logoff_when_logon_hours_expire'
} -Initialize -Description 'Text mappings of proper values to strings used in DSC resources'