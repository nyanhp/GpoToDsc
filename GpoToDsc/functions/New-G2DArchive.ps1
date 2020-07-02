<#
.SYNOPSIS
    Compress a self-contained archive to validate settings
.DESCRIPTION
    Compress a self-contained archive to validate settings
.PARAMETER Path
    Path to archive (either directory or .zip)
.PARAMETER ValidationObject
    The list of validation items from ConvertTo-G2DValidation
.EXAMPLE
    ConvertTo-G2DValidation -Path ./Policies -SkipMerge | New-G2DArchive -Path .\arch.zip

    Export an archive containing some mof files
#>
function New-G2DArchive
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidationItem[]]
        $ValidationObject
    )

    begin
    {
        $tempFolder = Join-Path -Path $env:TEMP -ChildPath GpoToDsc
        $moduleFolder = Join-Path -Path $tempFolder -ChildPath Modules

        is ($PSCmdlet.ShouldProcess('Creating folder', $moduleFolder))
        {
            if (Test-Path $tempFolder)
            {
                Remove-Item -Force -Recurse -Path $tempFolder
            }

            $null = New-Item -Path $moduleFolder -ItemType Directory -Force
            Save-Module -Name AuditPolicyDsc, SecurityPolicyDsc -Path $moduleFolder -Repository PSGallery

            $archivePath = if (-not (Test-Path -PathType Leaf -Path $Path))
            {
                Join-Path -Path $Path -ChildPath 'G2DArchive.zip'
            }
            else
            {
                $Path
            }
        }
    }

    process
    {
        if ($ValidationObject.ValidationType -contains 'Pester' -and -not (Test-Path -Path (Join-Path -Path $moduleFolder -ChildPath Pester)))
        {
            Save-Module -Name Pester, Format-Pester -Path $moduleFolder -Repository PSGallery
        }

        if ($PSCmdlet.ShouldProcess('Exporting validation things', 'ValidationCollection'))
        {
            foreach ($vObject in $ValidationObject)
            {
                $targetPath = Join-Path -Path $tempFolder -ChildPath $vObject.ValidationType
                if (-not (Test-Path -Path $targetPath))
                {
                    $null = New-Item -ItemType Directory -Path $targetPath
                }

                switch ($vObject.ValidationType)
                {
                    'Pester'
                    {
                        $null = Export-G2DPesterSuite -Path $targetPath -Configuration $vObject
                    }
                    'Dsc'
                    {
                        $null = Export-G2DConfiguration -Path $targetPath -Configuration $vObject
                    }
                    default
                    {
                        throw 'What the hell happened...'
                    }
                }
            }
        }
    }

    end
    {
        if ($PSCmdlet.ShouldProcess('Saving archive', $archivePath))
        {
            Compress-Archive -Path $tempFolder\* -DestinationPath $archivePath -Force
        )
    }
}
