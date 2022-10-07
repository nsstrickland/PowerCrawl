<#
# File: output.ps1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Friday, 7th October 2022 1:45:47 am
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

class contentBox {
    [int]$Height;
    [int]$Width;
    [string[]]$Content;
    [string[]]$RenderedContent;
    hidden [string[]]$edgeCharacters;
    hidden [int]$HostHeight=(Get-Host).UI.RawUI.BufferSize.Height;
    hidden [int]$HostWidth=(Get-Host).UI.RawUI.BufferSize.Width;
    hidden [int]$maxDrawWidth=($This.HostWidth/2);
    hidden [int]$maxInteriorWidth=$this.maxDrawWidth-4;
    hidden [int]$drawWidth;
    hidden [int]$drawHeight=($This.HostHeight/2);
    contentBox([string]$Content){
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═')
        $this.processContent($Content)
        $this.addTitle()
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }
    contentBox([string]$Title,[string]$Content){ #TODO: adjust width to title if content is shorter
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═')
        $this.processContent($Content)
        $this.addTitle($title)
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }
    contentBox(){
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═')
    }
    [void]processContent([string]$Content){
        $maxWidth=$this.maxInteriorWidth
        if ($Content.Length -ge $this.maxInteriorWidth) {
            $this.Content = $Content -split "(.{$maxWidth})" | Where-Object {$_}
            $this.drawWidth=$this.maxDrawWidth} else {
               $this.Content=$Content
                $this.drawWidth=[int]($Content.Length + 4)
        }
    }
    [string]padString([string]$string,[string]$padChar) {
        [int]$pad=([Math]::Max(0,$this.drawWidth/2) - [Math]::Ceiling($string.length / 2))
        return [string]("{0}{1}{2}" -f ([string]$padChar*[int]$pad),$string,[string]($padChar*[int]($this.drawWidth-$pad-$string.Length))) 
    }
    [void]addBody([string]$string){
        $this.RenderedContent+=[string]($this.edgeCharacters[4]+$this.padString($string,' ')+$this.edgeCharacters[4])
    }
    [void]addTitle([string]$string){
        $this.RenderedContent+=[string]($this.edgeCharacters[0]+($this.padString($string,'═'))+$this.edgeCharacters[1])
    }
    [void]addTitle(){
        $this.RenderedContent+=[string]($this.edgeCharacters[0]+($this.edgeCharacters[5]*([int]$this.drawWidth))+$this.edgeCharacters[1])
    }
    [void]addSubtitle([string]$string){
        $this.RenderedContent+=[string]($this.edgeCharacters[4]+($this.padString($string,' ')).Replace($string,("$string`e[24m").Insert(0,"`e[4m"))+$this.edgeCharacters[4])
    }
    [void]addEnd(){
        $this.RenderedContent+=[string]($this.edgeCharacters[2]+($this.edgeCharacters[5]*($this.drawWidth))+$this.edgeCharacters[3])
    }
    [string[]]ToString(){
        return [string[]]$this.RenderedContent
    }

}

class popupBox : contentBox {
    hidden $originalCursorPosition;
    
    popupBox([string]$title,[string]$Content) {
        $this.processContent($Content)
        $this.addTitle($title)
        $lineno=0
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }

    [void]render() {
        $this.originalCursorPosition=[System.Console]::GetCursorPosition()
        $renderPadX=([Math]::Max(0,$this.HostWidth/2) - [Math]::Ceiling($this.RenderedContent[0].length / 2))
        $renderPadY=([Math]::Max(0,([int]$this.drawHeight)/2) - [Math]::Ceiling($this.RenderedContent.count / 2))
        foreach ($line in $this.RenderedContent) {
            [System.Console]::SetCursorPosition($renderPadX,$renderPadY)
            [System.Console]::Write($line)
            $renderPadY++
        }
        [System.Console]::SetCursorPosition($this.originalCursorPosition.Item1,$this.originalCursorPosition.Item2)
        [System.Console]::CursorVisible=$false
        do{ $x=[System.Console]::ReadKey(“NoEcho, IncludeKeyUp”) } while( $x.Key -ne "F2" )
    }

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
    hidden [int]$interiorWidth
    #hidden [int]$interiorHeight
    hidden [int]$maxDrawWidth=($This.HostWidth/2)
    hidden [int]$maxInteriorWidth=$this.maxDrawWidth-4
    hidden [string[]]$Payload=@()

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
        return 1
    }
    [void]processContent([string]$string) {
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