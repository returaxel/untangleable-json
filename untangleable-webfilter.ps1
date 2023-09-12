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
    [Parameter()][switch]$OutSkipped,
    [Parameter()][switch]$OutFile
)

function RegexMagic {
    param (
        [Parameter()][array]$BlockList,
        [Parameter()][string]$Regex = '(?:^[\w]*\ )?(\b[\w\-\*]+)(\.?[\w\.\-\*]*)(\.[\w\.\-\*]+(?:[\W]*?$))'
    ) 

    $BlockList | ForEach-Object {

        # Skip blocklist comments, edit regex as needed
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

            if (-not[string]::IsNullOrEmpty($RegexMatch)) {

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
                
                if ($OutFile) {
                    if (![string]::IsNullOrEmpty($RegexMagic.FullMatch) -and ($RegexMagic.WellFormed)) {
                        $RegexMagic.string = $RegexMagic.FullMatch
                    }
                }

                return $RegexMagic

            }

        }         
        elseif ($OutSkipped) {
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
Write-Host "`n Source: $($BlockList.Length) entries (including comments)"
Write-Host " Output: $($RegexMagic.Length) entries"
Write-Host " RunTime: $($RunTime.TotalSeconds) seconds"
if ($OutFile) {
    Write-Host " FilePath: $($FilePath)`n"
}