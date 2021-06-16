
<#
.DESCRIPTION
    - Input URL of >DOMAIN< block list. Output Untangle-Importable version, or fail miserably.
.PARAMETER OutFile
    - Path & name of exported file
.PARAMETER BlockListURL
    - URL of selected list (.txt)
.NOTES
    Version:        1
    Author:         returaxel
    Creation Date:  2021-06-16 
.EXAMPLE
    .\untangleable-webfilter.ps1 -OutFile C:\Temp\My.json -BlockListURL "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
#>

[CmdletBinding()]
param (
    [Parameter()][string]$OutFile = "$($ENV:OneDrive)\UntangleAbleDNSBlockList.json",
    [Parameter()][string]$BlockListURL = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
)

class UntangleAbleDNSBlockList {
    [object]$string = $null
    [object]$blocked = $true
    [object]$flagged = $true
    [object]$javaClass = 'com.untangle.uvm.app.GenericRule'
    [object]$markedForNew = $true
    [object]$description = ''
    [object]$markedForDelete = $false

    UntangleAbleDNSBlockList ([string]$string)
    {
        # Removes special characters
        # https://lazywinadmin.com/2015/08/powershell-remove-special-characters.html
        $this.string = $string.TrimStart('127.0.0.1') -replace '[^\p{L}\p{Nd}\.\*\^\-]', ''
    }
}

Measure-Command { # START MEASURE

$url = $BlockListURL
$array = (Invoke-WebRequest $url).Content -Split "`n"

[psobject]$untangleable = foreach ($row in $array) {
    if ($row -notmatch '!|@|#') {
        [UntangleAbleDNSBlockList]::new($row)
    }
}

} # END MEASURE

# $untangleable | Out-GridView -Title $BlockListURL # Uncomment to show preview in Lidl-Excel
$untangleable | ConvertTo-Json | Set-Content $OutFile
