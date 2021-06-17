# to be continued

class AdBlockerRow{
    [object]$blocked   = $true
    [object]$flagged   = $true
    [object]$string    = $null
    [object]$javaClass = "com.untangle.uvm.app.GenericRule"
    [object]$name      = $null
    [object]$description= $null
    [object]$readOnly  = $null
    [object]$id        = $null
    [object]$category  = $null
    [object]$enabled   = $true

    AdBlockerRow([string]$string)
    {
        $this.string = $string
    }
}