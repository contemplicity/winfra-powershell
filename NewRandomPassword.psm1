function New-RandomPassword {
    Param(
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
        [ValidateRange(8,127)]
        [int]
        $length=30
    )

    $RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    $pwd = @()

    Do {
        [byte[]]$byte = [byte]1
        $RNG.GetBytes($byte)
        if ($byte[0] -lt 33 -or $byte[0] -gt 126) {continue}
        $pwd += $byte[0] 
    } 

    While ($pwd.count -lt $length)

    $pwd = ([char[]]$pwd) -join ''

    $pwd

}
