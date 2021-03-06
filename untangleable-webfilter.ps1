
<#
.DESCRIPTION
    Input list of domains to block -> Output Untangle WebFilter-App compatible json file, or fail miserably.
    
    Regex inspiration https://lazywinadmin.com/2015/08/powershell-remove-special-characters.html

.PARAMETER OutFile
    Path & name of exported file

.PARAMETER BlockListURL
    URL of selected list (.txt)

.PARAMETER CompareName
    Compare the original domains with parsed output in Grid-View. Useful for finding errors.

.NOTES
    Creation Date:  2021-06-16 

.EXAMPLE
    .\untangleable-webfilter.ps1 -OutFile C:\Temp\My.json -BlockListURL "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"
    
    Verified lists: Converted, uploaded & hopefully blocking :)
        - https://raw.githubusercontent.com/lassekongo83/Frellwits-filter-lists/master/Frellwits-Swedish-Hosts-File.txt
        - https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
        - https://adaway.org/hosts.txt
#>

[CmdletBinding()]
param (
    [Parameter()][string]$OutFile = "$($ENV:OneDrive)\WebFilter.json",
    [Parameter()][string]$BlockListURL = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt",
    [Parameter()][switch]$CompareName

)

class WebFilterRow {
    hidden[object]$original = $null
    [object]$string = $null
    [object]$blocked = $true
    [object]$flagged = $true
    [object]$javaClass = 'com.untangle.uvm.app.GenericRule'
    [object]$markedForNew = $true
    [object]$description = $null
    [object]$markedForDelete = $false

    WebFilterRow ([string]$original, [string]$string)
    {
        $this.original = $original.Trim()
        $this.string = $string.Trim()
    }
}

# Removes special characters
function RegExMagic {
    param (
        [Parameter()][string]$string
    )
    switch -regex ($string)
    {
        # TrimStart of IPv4 addresses
        '^.?\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' {
            $string = $string.TrimStart([regex]::Match($string,'^.?\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b').Captures.Value)
        }
        # TrimStart of special characters 
        '^[^\p{L}\p{Nd}]*' { 
            $string = $string.TrimStart([regex]::Match($string,'^[^\p{L}\p{Nd}]*').Captures.Value) 
        }
        # Remove every special character from string except \.\*\-\/
        '[^\p{L}\p{Nd}\.\*\-]'{
            $string = $string -replace '[^\p{L}\p{Nd}\.\*\-\/]', ''
        }
    }
    # Validate URL
    if ([regex]::Match($string,'^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?').Success){
        return $string
    }
}

$RunTime = Measure-Command { # START MEASURE

$BlockListArray = (Invoke-WebRequest $BlockListURL).Content -Split "`n"

[psobject]$UntangleAble = foreach ($row in $BlockListArray) {
    if ($row -notmatch '!|@|#' -and $row -match '[a-z]|[0-9]') {
        $domain = RegExMagic $row
        if ($null -ne $domain) {
            [WebFilterRow]::new($row,$domain)
        }
    }
}

} # END MEASURE

Write-Output "`n Source: $($BlockListArray.Length) rows"
Write-Output " Output: $($UntangleAble.Length) rows`n"
Write-Output " RunTime: $($RunTime.TotalSeconds) seconds`n"
Write-Output " FilePath: $($OutFile)`n"

if ($CompareName) {
    $UntangleAble | Select-Object original, string | Out-GridView -Title $BlockListURL
}

$UntangleAble | ConvertTo-Json | Set-Content $OutFile
