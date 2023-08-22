<#
.DESCRIPTION
    --------- DISCLAIMER ---------
            Might not work.
    -------------------------------
    Input BlockListURL > Output > Untangle WebFilter-App compatible json file (or fail miserably)
    Use pipeline to get prettier output. See examples.

.PARAMETER FilePath
    Where to save the .json

.PARAMETER BlockListURL
    A list of domains to block
    
.PARAMETER ShowAll
    View skipped entries in terminal

.PARAMETER OutFile
    Save as .json

.NOTES
    Author: returaxel
    Updated: New regex, that actually does what I want. 
        3 capture groups; SUB, SLD, TLD. Second-Level should hold everything except SUB and Top-Level.

.EXAMPLE
    View output
        .\untangleable-webfilter.ps1 -BlockListURL 'https://raw.githubusercontent.com/returaxel/untangleable-json/main/TestList.txt' | Out-GridView
    
    Save as json
        .\untangleable-webfilter.ps1 -BlockListURL 'https://raw.githubusercontent.com/returaxel/untangleable-json/main/TestList.txt' -OutFile

#>

param (
    [Parameter()][string]$BlockListURL,
    [Parameter()][string]$FilePath = "$($ENV:OneDrive)\WebFilter.json",
    [Parameter()][switch]$ShowAll,
    [Parameter()][switch]$OutFile
)

function RegexMagic {
    param (
        [Parameter()][array]$BlockList,
        # TestList: 41/41 matches, 2109 steps
        [Parameter()][string]$Regex = '^(?:[^\w*-]*(?:\d+(?:\.\d+)+[^\w*-]+)?)([\w\-\*]+)(\.?[\w\.\-\*]*)(\.[\w\.\-\*]+)' 
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
                $RegexMagic.TLD = $RegexMatch.Groups[3].Value # Top level domain, everything after the last punctuation
                $RegexMagic.FullMatch = '{0}{1}{2}' -f $RegexMatch.Groups[1],$RegexMatch.Groups[2],$RegexMatch.Groups[3]
            }
            catch {
                Write-Host $RegexMagic.URL -ForegroundColor DarkYellow
            } 

            $RegexMagic.WellFormed = [Uri]::IsWellFormedUriString($RegexMagic.FullMatch, 'Relative')
            
            if (![string]::IsNullOrEmpty($RegexMagic.FullMatch) -and ($RegexMagic.WellFormed)) {
                $RegexMagic.string = $RegexMagic.FullMatch
                return $RegexMagic
            }
        }         
        elseif ($ShowAll) {
            Write-Host $_ -ForegroundColor DarkGray
        }

    }

}

$RunTime = Measure-Command { # START MEASURE

# Iterate list: might need tweaking depending on format
[array] $BlockList = (Invoke-WebRequest $BlockListURL -UseBasicParsing).Content -split '\r?\n'

$RegexMagic = RegexMagic -BlockList $BlockList

} # END MEASURE

if ($OutFile) {
    $RegexMagic | Select-Object string, blocked, flagged, javaclass, markedfornew, description, markedfordelete | ConvertTo-Json | Set-Content $FilePath
}

$RegexMagic | Select-Object URL, SUB, SLD, TLD, FullMatch, WellFormed 

Write-Host "`n"
Write-Host "`n Source: $($BlockList.Length) entries"
Write-Host " Output: $($RegexMagic.Length) entries"
Write-Host " RunTime: $($RunTime.TotalSeconds) seconds"
Write-Host " FilePath: $($FilePath)`n"