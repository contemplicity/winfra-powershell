param($numberOfDays=30)

Write-Host -ForegroundColor Magenta "Generating list of DCs:`n"

Import-Module ActiveDirectory

($DCS = Get-ADForest | select -exp GlobalCatalogs)


$scriptBlock = {

    param($numberOfDays)

    function Get-PatchStateReport {

        param($numberOfDays=30)

         $qfe = Get-WmiObject win32_quickfixengineering
         $LastNDays = $qfe | ?{$_.installedOn -gt (Get-Date).AddDays(-$numberOfDays)}

         if ($LastNDays) {$LastNDays} else {Write-Output "$env:computername : No patches installed in the last $numberOfDays days"}

        }

    Get-PatchStateReport $numberOfDays

}

Write-Host -ForegroundColor Magenta "`nGetting patch state report for the previous $numberOfDays days..."

$null = Invoke-Command -ComputerName $DCs -ScriptBlock $scriptBlock  -AsJob -JobName PatchStateQry  -ArgumentList @(($numberOfDays=$numberOfDays))

Get-Job PatchStateQry | Wait-Job | Receive-Job -OutVariable Patches

Get-Job PatchStateQry | Remove-Job


$Global:Patches = $Patches
