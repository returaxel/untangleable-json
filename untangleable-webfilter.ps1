[CmdletBinding()]
param (
    [Parameter()][string]$OutFile = "$($ENV:USERPROFILE)\Documents\UntangleAbleDNSBlockList.json",
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
        $this.string = ($string -replace '[^\p{L}\p{Nd}\.\*\^]', '') # https://lazywinadmin.com/2015/08/powershell-remove-special-characters.html
    }
}

Measure-Command { # START MEASURE

$url = $BlockListURL
$array = (Invoke-WebRequest $url).Content -Split "`n"

[psobject]$untangleable = foreach ($row in $array) {
    if ($row -notmatch '!|@') {
        [UntangleAbleDNSBlockList]::new($row)
    }
}

} # END MEASURE

# $untangleable | Out-GridView -Title $BlockListURL # Uncomment to show preview in Lidl-Excel
$untangleable | ConvertTo-Json | Set-Content $OutFile
