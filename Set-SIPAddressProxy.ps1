
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
        [string[]]$users,

        # target domain
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$domain='win.stanford.edu'


    )


Try {Import-Module -Name ActiveDirectory -ErrorAction Stop} Catch [System.IO.FileNotFoundException]{Write-Warning "ActiveDirectory module needed. Exiting."; break} 


if (!(Get-Module -name ActiveDirectory)) {Write-Warning "ActiveDirectory module needed. Exiting."; break}

if (!(Get-ADDomain $domain -ErrorAction SilentlyContinue)) {
    Write-Warning "You must conect to the $domain domain. Engage Ring-0 VPN and run this script with root credentials." 
 
}


function Set-SIPAddressProxy {

    param (       
       [Parameter(Mandatory=$true,Position=0)]
       [string]$user,

       [string]$domain,

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

         $uAcct | Set-ADuser -Server $domain -Remove @{ProxyAddresses=$oldName} -verbose -WhatIf

        }
    
    } # end if

    if ($log) {
        $uAcct = Get-ADuser $user -properties ProxyAddresses -Server $domain 
        $uAcct | select -exp ProxyAddresses | export-clixml "$logpath\proxyAddresses_after_$user.xml" -Force       
    }

    $uAcct.ProxyAddresses

}


# main 


if ($importFilePath) {$users = cat $importFilePath}

foreach ($user in $users) {

Write-Host -fore DarkCyan "`nSetting SIP Address proxy attribute for " -NoNewline
Write-Host -fore Magenta "$user"

Set-SIPAddressProxy -user $user -domain $domain | FT


}

<### Usage Examples

# Example 1: users in a txt file, one sunetID per line

 .\source\Set-SIPAddressProxy.ps1 -importFilePath C:\Users\Public\skypers.txt 

# Example 2: users passed inline, as a list of 1 or more sunetIDs 

.\source\Set-SIPAddressProxy.ps1 -users idouglas,rkaul1,jkverno

###>
