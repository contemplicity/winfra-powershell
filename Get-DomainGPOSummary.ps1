function Get-DomainGPOSummary($domain)
{

Import-Module GroupPolicy

Write-Verbose "Getting all GPO objects in domain $domain" -Verbose

$GPOs = Get-GPO -All -Domain $domain -Verbose

$GPOs | %{ 

    $GPO = $_

    Write-Verbose "processing GPO $($GPO.ID): $($GPO.displayname)" -Verbose

    $rpt = [xml](Get-GPOReport -Guid $GPO.ID.guid -ReportType Xml -Domain $domain)
    $dict = @{
        DisplayName = $GPO.DisplayName
        DomainName =  $GPO.DomainName
        Owner = $GPO.Owner
        ID = $GPO.ID
        GPOStatus = $GPO.GpoStatus
        Description = $GPO.Description
        CreationTime = $GPO.CreationTime
        ModificationTime =  $GPO.ModificationTime
        SOMName = $rpt.Gpo.LinksTo.SOMName
        SOMPath = $rpt.Gpo.LinksTo.SOMPath
        Enabled = $rpt.Gpo.LinksTo.Enabled
        NoOverride = $rpt.Gpo.LinksTo.NoOverride
        Link = ''
    }

    if($rpt.Gpo.LinksTo -eq $NULL) {$dict.Link = $False} else {$dict.Link = $True}

    [pscustomobject]$dict

}

}

$domain = 'it.win.stanford.edu'

$GPOSummary_IT = Get-DomainGPOSummary $domain

$GPOSummary_IT | Export-Csv ".\DomainGPOSummary_$($domain).csv" -Verbose

<# Usage Example 1 : filter inline and delete

$GPOSummary_IT | ?{$_.DisplayName -match '^WFW' -and $_.DisplayName -notmatch 'WFW Template' -and $_.link -eq $false } | %{write-host "deleting $($_.Displayname)" ; Remove-Gpo -Guid $_.ID -Domain $domain -KeepLinks -Verbose -WhatIf }

#> 

<# Usage Example 3: after editing  exported CSV file, re-import edited CSV, and delete GPOs

$GPOSummary_IT_Imported = Import-Csv ".\DomainGPOSummary_$($domain).csv" -Verbose

$GPOSummary_IT_Imported | ?{$_.DisplayName -match '^WFW' -and $_.DisplayName -notmatch 'WFW Template' -and $_.link -eq $false } | %{write-host "deleting $($_.Displayname)" ; Remove-Gpo -Guid $_.ID -Domain $domain -KeepLinks -Verbose -WhatIf }
 
#>

