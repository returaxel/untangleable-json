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

    # HashTable TEST
    $OutHash = [ordered]@{}

    # Iterate Blocklist, add to HashTable
    $BlockList | ForEach-Object {

        # Skip blocklist comments, edit regex as needed
        if (![string]::IsNullOrWhiteSpace($_) -and ($_ -notmatch '!|@|#')) {
    
            $RegexMatch = [regex]::Matches($_, $Regex)

            if (-not[string]::IsNullOrEmpty($RegexMatch)) {

                try {

                    $Key = if ([string]::IsNullOrEmpty($RegexMatch.Groups[2])) {
                        '{0}{1}' -f $RegexMatch.Groups[1],$RegexMatch.Groups[3]
                    } else {
                        '{0}{1}' -f $RegexMatch.Groups[2],$RegexMatch.Groups[3]
                    }

                    if ($key -in $OutHash.Keys) {
                        $OutHash[$Key].SUB.Add($RegexMatch.Groups[1], $null)
                    }

                    $OutHash.$key = [pscustomobject]@{
                        # Information
                        URL = $_
                        SUB = @($RegexMatch.Groups[1].Value, $null) # Sub domain(s)
                        SLD = $RegexMatch.Groups[2].Value # Second level domain 
                        TLD = $RegexMatch.Groups[3].Value # Top level domain, everything after the last punctuation
                        FullMatch = '{0}{1}{2}' -f $RegexMatch.Groups[1],$RegexMatch.Groups[2],$RegexMatch.Groups[3]
                        WellFormed = [Uri]::IsWellFormedUriString($RegexMagic.FullMatch, 'Relative')
                    }

                }
                catch {
                    Write-Host 'HashTable_Flip' -ForegroundColor DarkYellow
                }

            }

        }         
        elseif ($OutSkipped) {
            Write-Host $_ -ForegroundColor DarkGray
        }

    }
    return $OutHash 

}

$RunTime = Measure-Command { # START MEASURE

# Iterate list: might need tweaking depending on format
[array] $BlockList = (Invoke-WebRequest $BlockListURL -UseBasicParsing).Content -split '\r?\n'

$RegexMagic = RegexMagic -BlockList $BlockList

} # END MEASURE

$RegexMagic

Write-Host "`n"
Write-Host "`n Source: $($BlockList.Length) entries (including comments)"
Write-Host " Output: $($RegexMagic.keys.count) entries"
Write-Host " RunTime: $($RunTime.TotalSeconds) seconds"