<#
.DESCRIPTION
    Input BlockListURL > Output > Untangle WebFilter-App compatible json file, or fail miserably.

.PARAMETER FilePath
    Where to save the .json

.PARAMETER BlockListURL
    A list of domains to block

.PARAMETER OutFile
    Save as .json 

.NOTES
    Author: returaxel
    Updated: rewritten because regex is hard to comprehend, faster and perhaps smarter than before

    Possibly better but does not match domains that end with a space followed by a character (42 matches, 6223 steps)
    (?=\b(\.?[\w\-\*]*+)([\w\.\-\*]*)(\.{1}[\w\-\*]+?\b))(?:\S*\s?)$

.EXAMPLE
    View output
        .\untangleable-webfilter.ps1 -BlockListURL 'https://raw.githubusercontent.com/returaxel/untangleable-json/main/TestList.txt' | Out-GridView
    
    Save as json
        .\untangleable-webfilter.ps1 -BlockListURL 'https://raw.githubusercontent.com/returaxel/untangleable-json/main/TestList.txt' -OutFile

#>

param (
    [Parameter()][string]$BlockListURL,
    [Parameter()][string]$FilePath = "$($ENV:OneDrive)\WebFilter.json",
    [Parameter()][switch]$OutFile
)

function RegexMagic {
    param (
        [Parameter()][array]$BlockList,
        # 46 matches, 10698 steps, matches domains that end with a space and space followed by a character
        [Parameter()][string]$Regex = '(?=\b([\w\-\*]*)(\b[\w\.\-\*]*)(\.{1}[\w\.\-\*]+))(?:\S*\s*?\W*?)$' 
    ) 

    $BlockList | ForEach-Object {

        # Skip if empty or contain the following characters 
        if (![string]::IsNullOrWhiteSpace($_) -and ($_ -notmatch '!|@|#')) {

            # Make object for output
            $RegexMagic = [PSCustomObject]@{
                # Information
                URL = $_
                SUB = $null
                SLD = $null
                TLD = $null
                FullMatch = $null
                WellFormed = $null
                # Ruleset
                string = $null
                blocked = $true
                flagged = $true
                javaClass = 'com.untangle.uvm.app.GenericRule'
                markedForNew = $true
                description = $null
                markedForDelete = $false
            }    
    
            $RegexMatch = [regex]::Matches($_, $Regex)

            try {
                $RegexMagic.SUB = $RegexMatch.Groups[1].Value # Sub domain
                $RegexMagic.SLD = $RegexMatch.Groups[2].Value # Second level domain
                $RegexMagic.TLD = $RegexMatch.Groups[3].Value # Top level domain, everything after the second dot
                $RegexMagic.FullMatch = '{0}{1}{2}' -f $RegexMatch.Groups[1],$RegexMatch.Groups[2],$RegexMatch.Groups[3]
            }
            catch {
                Write-Host $RegexMagic.URL
            }

            $RegexMagic.WellFormed = [Uri]::IsWellFormedUriString($RegexMagic.FullMatch, 'Relative')
            
            if (![string]::IsNullOrEmpty($RegexMagic.FullMatch) -and ($RegexMagic.WellFormed)) {
                $RegexMagic.string = $RegexMagic.FullMatch
                return $RegexMagic
            }

        }         
        else {
            # Uncomment to show skipped entries, slightly slower
            # Write-Host $_ -ForegroundColor DarkGray
        }

    }

}

$RunTime = Measure-Command { # START MEASURE
    
[array] $BlockList = (Invoke-WebRequest $BlockListURL -UseBasicParsing).Content -split '\r?\n'

$RegexMagic = RegexMagic -BlockList $BlockList

} # END MEASURE

if ($OutFile) {
    $RegexMagic | Select-Object string, blocked, flagged, javaclass, markedfornew, description, markedfordelete | ConvertTo-Json | Set-Content $FilePath
}

# What's sent to the pipeline
$RegexMagic | Select-Object URL, SUB, SLD, TLD, FullMatch, WellFormed

Write-Host "`n Source: $($BlockList.Length) entries"
Write-Host " Output: $($RegexMagic.Length) entries"
Write-Host " RunTime: $($RunTime.TotalSeconds) seconds"
Write-Host " FilePath: $($FilePath)`n"