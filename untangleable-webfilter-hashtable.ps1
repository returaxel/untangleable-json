<#
.DESCRIPTION
    --------- DISCLAIMER ---------
            Might not work.
    -------------------------------
    Learning new things - terribly ineffective - don't use this

.PARAMETER BlockListURL
    A list of domains to block
    
.PARAMETER OutSkipped
    View skipped entries in terminal

.NOTES
    Author: returaxel
    Updated: Trying hashtable things.
        3 capture groups; SUB, SLD, TLD. Second-Level should hold everything except SUB and Top-Level.

.EXAMPLE
    Might want to output into a variable
        $EatTheOutput = .\untangleable-webfilter.ps1 -BlockListURL 'https://raw.githubusercontent.com/returaxel/untangleable-json/main/TestList.txt' 
    
#>

param (
    [Parameter()][string]$BlockListURL,
    [Parameter()][switch]$OutSkipped
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
                
                    } 
                    else {

                        '{0}{1}' -f $RegexMatch.Groups[2],$RegexMatch.Groups[3]

                    }

                    if ($OutHash[$Key] -as [bool]) {
                        try {
                            $OutHash[$Key].SUB.Add($RegexMatch.Groups[1], $null)
                        }
                        catch {
                            Write-Host "HashTable.Add()_Flip: $($OutHash[$Key])" -ForegroundColor DarkYellow
                        }

                    } 
                    else {
                        $OutHash.$Key = [pscustomobject]@{
                            # Information
                            URL = $_
                            SUB = @{$RegexMatch.Groups[1].Value = $null} # Sub domain(s)
                            SLD = $RegexMatch.Groups[2].Value # Second level domain 
                            TLD = $RegexMatch.Groups[3].Value # Top level domain, everything after the last punctuation
                            FullMatch = '{0}{1}{2}' -f $RegexMatch.Groups[1],$RegexMatch.Groups[2],$RegexMatch.Groups[3]
                            WellFormed = [Uri]::IsWellFormedUriString($RegexMagic.FullMatch, 'Relative')
                        }
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