<#
# File: output.ps1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Wednesday, 5th October 2022 12:17:56 am
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>


function Set-ConsoleLine {
    [CmdletBinding()]
    param (
        [parameter (Mandatory=$true)]
        [int]$Line,
        [parameter (Mandatory=$true)]
        [psobject]$InputObject
    )
}

function Clear-ConsoleLine {
    [CmdletBinding()]
    param (
        [parameter (Mandatory=$true)]
        [int]$Line
    )
    $ConsoleWidth=$host.ui.RawUI.BufferSize.Width;
    $Cur=[System.Console]::GetCursorPosition()
    [System.Console]::SetCursorPosition(0,$Line);
    [System.Console]::Write("{0,-$ConsoleWidth}" -f " ")
    [System.Console]::SetCursorPosition($Cur.Item1,$Cur.Item2)

}


class messageBox {
    # this entire class makes me crave death
    [string]$Title;
    [string]$Message;
    [string[]]$Buttons;
    [bool]$CenteredTitle;
    [int]$Height;
    [int]$Width;
    hidden [int]$HostHeight=(Get-Host).UI.RawUI.BufferSize.Height
    hidden [int]$HostWidth=(Get-Host).UI.RawUI.BufferSize.Width
    hidden [int]$BoundsX
    hidden [int]$BoundsY
    hidden [int]$maxDrawWidth=(($This.HostWidth/2) - 4)
    hidden [string[]]$Payload=@()
    #hidden [int]$maxWidth

    messageBox( [string]$Title, [string]$Message) {$this.Title=$Title;$this.Message=$Message;$this.Buttons=@("`e[4mO`e[24mk");$this.CenteredTitle=$false}
    messageBox(
        [string]$Title,
        [string]$Message,
        [bool]$YesNo #Change the default button from "Ok" to "Yes" and "No"
    ) {
        $this.Title=$Title;
        $this.Message=$Message;
        $this.CenteredTitle=$false;
        if ($YesNo) {$this.Buttons=@("`e[4mY`e[24mes","`e[4mN`e[24mo")} else {$this.Buttons=@("`e[4mO`e[24mk")}
    }
    messageBox(
        [string]$Title,
        [string]$Message,
        [bool]$YesNo, #Change the default button from "Ok" to "Yes" and "No"
        [bool]$CenteredTitle
    ) {
        $this.Title=$Title;
        $this.Message=$Message;
        $this.CenteredTitle=$CenteredTitle
        if ($YesNo) {$this.Buttons=@("`e[4mY`e[24mes","`e[4mN`e[24mo")} else {$this.Buttons=@("Ok")}
    }
    [int]getBounds() {
        $this.BoundsX=$this.maxDrawWidth
        <#
        $tl=$This.Title.Length
        if ($This.Message.Length -ge $this.maxDrawWidth) {
            $ml=$this.maxDrawWidth
            $this.BoundsX=$this.maxDrawWidth
        } else { 
            $ml=$This.Message.Length 
            $this.BoundsX=$ml
        } 
        if ($ml -le $tl) {$this.BoundsX = $tl}
        if (($ml -gt $tl) -and ($ml -lt $this.maxDrawWidth)) {$this.BoundsX=$ml+4}#>
        return $this.BoundsX
    }
    [hashtable]getPadding($string){
        if (($this.BoundsX - $string.length)/2 -like "*.*") {
            [string]$leftPad=' ' * ([math]::Truncate(($this.BoundsX - $string.length)/2))
            [string]$rightPad=' ' * ([math]::Truncate(($this.BoundsX - $string.length)/2)+1)
        } else {
            [string]$leftPad=' ' * ([math]::Truncate(($this.BoundsX - $string.length)/2))
            [string]$rightPad=$leftPad
        }
        if ($leftPad.Length -le 2) {$leftPad=' '}
        if ($rightPad.Length -le 2) {$rightPad=' '}

        return @{Left=$leftPad;Right=$rightPad}
    }
    [string]padString([string]$string,[string]$padChar) {
        return [string]("{0}{1}{0}" -f ($padChar*(([Math]::Max(0,$this.BoundsX/2) - [Math]::Floor($string.length / 2)))),$string)
    }
    [string[]]Process() {
        $this.getBounds()
        [string[]]$out=@()
        # Title
        # $titlePad=$this.getPadding($this.Title)
        # if ($this.CenteredTitle) {
        #     $out+=[string]("╔═"+$titlePad.Left.replace(' ','═')+$this.Title+$titlePad.Right.replace(' ','═')+"═╗")
        # } else {
        #     $out+=[string]("╔═"+$this.Title+$titlePad.Left.replace(' ','═')+$titlePad.Right.replace(' ','═')+"═╗")
        # }
        if ($this.Message.Length -gt $this.BoundsX) {
            $maxWidth = $this.BoundsX - 2
            [string[]]$messages = $this.Message -split "(.{$maxWidth})" | Where-Object {$_}
        } else {[string[]]$messages=$this.Message}
        # $out+=[string]('║'+(' ' * ($this.BoundsX+2))+'║')
        # foreach ($line in $messages) {
        #     $pad=$null;$pad=$this.getPadding($line.trim())
        #     $out+=[string]('║ '+$pad.Left+$line.trim()+$pad.Right+' ║')
        # }
        # $out+=[string]('║'+(' ' * ($this.BoundsX+2))+'║')
        # $buttonPad=$this.getPadding([string]$this.Buttons)
        $button = [string]($this.Buttons | ForEach-Object {
            return $PSItem.Insert(1,"`e[24m").Insert(0,"`e[4m")
        })
        # $out+=[string]('║ '+$buttonPad.Left+$button+$buttonPad.Right+' ║')
        # $out+=[string]('╚'+('═' * ($this.BoundsX+2))+'╝')
        $out+=[string]('╔═'+$this.padString($this.Title,'═')+'═╗')
        $out+=[string]('║ '+$this.padString('',' ')+' ║')
        foreach ($line in $messages) {
            $out+=[string]('║ '+$this.padString($line,' ')+' ║')
        }
        $out+=[string]('║ '+$this.padString($button,' ')+' ║')
        return $out
    }

}