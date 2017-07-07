
[CmdletBinding(DefaultParameterSetName='importFile')]
    Param
    (
        # file path to a txt file containing a list of SUNET IDs on each line
        [Parameter(Mandatory=$true,ParameterSetName='importFile')]
        [ValidateNotNullOrEmpty()]
        [string]$importFilePath,

        # one or many SUNET IDs passed inline as an array, eg "sunet1","sunet2"
        [Parameter(Mandatory=$true,ParameterSetName='inline')]
        [ValidateNotNullOrEmpty()]
        [string[]]$users


    )


Try {Import-Module -Name MSOnline -ErrorAction Stop} Catch [System.IO.FileNotFoundException]{Write-Warning "MSOnline module needed. Exiting."; break} 


if (!(Get-Module -name MSOnline)) {Write-Warning "MSOnline module needed. Exiting."; break}

if (!(Get-MsolDomain -ErrorAction SilentlyContinue)) {
    Write-Warning "You must conect to MS Online. Attempting logon..." 
    $aad_cred = Get-Credential -Message "Credential for MS Online"
    Connect-MsolService -Credential $aad_cred -Verbose
}

if (!(Get-MsolDomain -ErrorAction SilentlyContinue)) {Write-Warning "Unable to authenticate to MS Online. Exiting" ; break }


function Set-SIPAddressProxy {

    param (       
       [Parameter(Mandatory=$true,Position=0)]
       [string]$user,

       [string]$domain = 'win.stanford.edu',

       [switch]$replace = $FALSE,

       [string]$logpath = $env:temp,

       [switch]$log = $TRUE
    )

    $uAcct = Get-ADuser $user -properties ProxyAddresses -Server $domain
    $sipAddress = "sip:"+$($uAcct.UserPrincipalName)

    if ($log) {$uAcct | select -exp ProxyAddresses | export-clixml "$logpath\proxyAddresses_before_$user.xml" -Force}

    Write-Verbose "Setting ProxyAddresses attribute:  $sipAddress " -Verbose

   $uAcct | Set-ADuser -Server $domain -Add @{ProxyAddresses=$sipAddress} -verbose  

    if ($replace) {
    
    if ($uAcct.ProxyAddresses -match 'skype.stanford.edu') {

        $oldName = $uAcct.ProxyAddresses -match 'skype.stanford.edu'

         $uAcct | Set-ADuser -Server $domain -Remove @{ProxyAddresses=$oldName} -verbose 

        }
    
    } # end if

    if ($log) {
        $uAcct = Get-ADuser $user -properties ProxyAddresses -Server $domain
        $uAcct | select -exp ProxyAddresses | export-clixml "$logpath\proxyAddresses_after_$user.xml" -Force       
    }

    $uAcct.ProxyAddresses

}


function Set-SkypeUserLicenseActive {

param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$user
)


Try {

    $AADUser = Get-MsolUser -UserPrincipalName ($user+"@stanford.edu") -ErrorAction Stop

    for ($i=0; $i -lt $AADUser.Licenses.Count; $i++) {

        if ($AADUser.Licenses[$i].serviceStatus.ServicePlan.ServiceName -eq 'MCOSTANDARD') {

            $skuID = $AADUser.Licenses[$i].AccountSkuid 
            $skuOption = New-MsolLicenseOptions -AccountSkuId $skuID  -DisabledPlans 'YAMMER_EDU' 
            
            Write-Verbose "Setting MSOL user license for $($AADUser.UserPrincipalName): $skuID with $($skuOption.DisabledServicePlans) disabled" -Verbose
             
            Set-MsolUserLicense -UserPrincipalName $AADUser.UserPrincipalName -LicenseOptions $skuOption -Verbose

            } 

        }

    (Get-MsolUser -UserPrincipalName ($user+"@stanford.edu")).Licenses.serviceStatus 

    } 

Catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException]{ Write-Warning "user $user@stanford.edu not found in Azure AD or licensing error" }

Catch { Write-Warning "unknown error when processing $user@stanford.edu" }

}

# main 


if ($importFilePath) {$users = cat $importFilePath}

foreach ($user in $users) {

Write-Host -fore DarkCyan "`nSetting SIP Address proxy attribute and applying Skype license for $user"

Set-SIPAddressProxy -user $user | FT

Set-SkypeUserLicenseActive -user $user | FT


}
   
