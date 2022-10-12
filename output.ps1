<#
# File: output.ps1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Sunday, 9th October 2022 3:51:37 pm
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>


class contentBox {
    [int]$Height;
    [int]$Width;
    [string]$Title
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
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═','╠','╣')
        $this.processContent($Content)
        $this.addTitle()
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }
    contentBox([string]$Title,[string]$Content){
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═','╠','╣')
        $this.Title = $Title
        $this.processContent($Content)
        $this.addTitle($title)
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }
    contentBox(){
        $this.edgeCharacters=@('╔','╗','╚','╝','║','═','╠','╣')
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
    [void]reProcessContent() {
        $this.RenderedContent=$null
        [string[]]$this.RenderedContent
        $this.processContent([string]$this.Content)
        if ($this.Title) {
            $this.addTitle($this.Title)
        } else {
            $this.addTitle()
        }
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
    }
    [string]padString([string]$string,[string]$padChar) {
        [int]$pad=([Math]::Max(0,$this.drawWidth/2) - [Math]::Ceiling($string.length / 2))
        return [string]("{0}{1}{2}" -f ([string]$padChar*[int]$pad),$string,[string]($padChar*[int]($this.drawWidth-$pad-$string.Length))) 
    }
    [void]addBody([string]$string){
        $this.RenderedContent+=[string]($this.edgeCharacters[4]+$this.padString($string,' ')+$this.edgeCharacters[4])
    }
    [void]addTitle([string]$string){
        $this.RenderedContent+=[string]($this.edgeCharacters[0]+($this.edgeCharacters[5]*([int]$this.drawWidth))+$this.edgeCharacters[1])
        $this.RenderedContent+=[string]($this.edgeCharacters[4]+($this.padString($string,' '))+$this.edgeCharacters[4])
        $this.RenderedContent+=[string]($this.edgeCharacters[6]+($this.edgeCharacters[5]*([int]$this.drawWidth))+$this.edgeCharacters[7])
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
        if ($this.bufferChanged()) {$this.reProcessContent()}
        return [string[]]$this.RenderedContent
    }
    [bool]bufferChanged() {
        $HH=(Get-Host).UI.RawUI.BufferSize.Height
        $HW=(Get-Host).UI.RawUI.BufferSize.Width
        if (($this.HostHeight -ne $HH) -or ($this.HostWidth -ne $HW)) {
            $this.HostHeight=$HH;
            $this.HostWidth=$HW;
            $this.maxDrawWidth=($This.HostWidth/2);
            $this.maxInteriorWidth=$this.maxDrawWidth-4;
            $this.drawHeight=($This.HostHeight/2);
            return 1
        } else {
            return 0
        }
    }
}

class popupBox : contentBox {
    [string[]]$buttons;
    hidden $originalCursorPosition;
    hidden $oldText;
    hidden [System.Management.Automation.Host.BufferCell[,]]$buffer;
    
    popupBox([string]$title,[string]$Content) {
        $this.Title=$title
        $this.processContent($Content)
        $this.addTitle($title)
        foreach ($line in $this.Content) {
            $this.addBody($line)
        }
        $this.addEnd()
        $this.buffer = New-Object 'System.Management.Automation.Host.BufferCell[,]' ($this.RenderedContent[0].Length),$this.RenderedContent.Count
        $this.generateBuffer()
    }
    # popupBox([string]$title,[string]$Content,[string[]]$Buttons) {
    #     $this.processContent($Content)
    #     $this.addTitle($title)
    #     foreach ($line in $this.Content) {
    #         $this.addBody($line)
    #     }
    #     $this.addEnd()
    # }
    
    generateBuffer() {
        $tmp = [System.Management.Automation.Host.BufferCell[,]]::new(($this.RenderedContent.Count),($this.RenderedContent[0].Length))
        for ($i = 0; $i -lt ($this.RenderedContent.Count); $i++) {
            for ($j = 0; $j -lt ($this.RenderedContent[0].Length); $j++) {
                $tmp[$i,$j]=[System.Management.Automation.Host.BufferCell]::new($this.RenderedContent[$i][$j],[System.ConsoleColor]'Gray',[System.ConsoleColor]'Black',[System.Management.Automation.Host.BufferCellType]'Complete')
            }
        }
        $this.buffer=$tmp
    }

    [void]render() {
        write-host $this.RenderedContent[0].Length
        if ($this.bufferChanged()) {
            $this.reProcessContent()
            Start-Sleep -Milliseconds 100
            $this.buffer = New-Object 'System.Management.Automation.Host.BufferCell[,]' ($this.RenderedContent[0].Length),$this.RenderedContent.Count
            $this.generateBuffer()
        }
        write-host $this.RenderedContent[0].Length
        $this.originalCursorPosition=[System.Console]::GetCursorPosition()
        $renderPadX=([Math]::Max(0,$this.HostWidth/2) - [Math]::Ceiling($this.RenderedContent[0].length / 2))
        $renderPadY=([Math]::Max(0,([int]$this.HostHeight)/2) - [Math]::Ceiling($this.RenderedContent.count / 2))

        #Start old string capture
        $rectangle = [System.Management.Automation.Host.Rectangle]::new($renderPadX,$renderPadY,($renderPadX+$this.RenderedContent[0].Length),($renderPadY+$this.RenderedContent.Count))
        $bufferSection = (Get-Host).UI.RawUI.GetBufferContents($rectangle)
        $this.oldText=$bufferSection
        (Get-Host).UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new($renderPadX,$renderPadY),$this.buffer)
        [System.Console]::SetCursorPosition($this.originalCursorPosition.Item1,$this.originalCursorPosition.Item2)
        [System.Console]::CursorVisible=$false
        do{ $x=[System.Console]::ReadKey(“NoEcho, IncludeKeyUp”) } while($null -eq $x)
        $this.deRender()
    }
    [void]deRender() {
        $renderPadX=([Math]::Max(0,$this.HostWidth/2) - [Math]::Ceiling($this.RenderedContent[0].length / 2))
        $renderPadY=([Math]::Max(0,([int]$this.HostHeight)/2) - [Math]::Ceiling($this.RenderedContent.count / 2))
        #$rectangle = [System.Management.Automation.Host.Rectangle]::new($renderPadX,$renderPadY,($renderPadX+$this.RenderedContent[0].Length),($renderPadY+$this.RenderedContent.Count))
        #(Get-Host).UI.RawUI.SetBufferContents([System.Management.Automation.Host.Rectangle]$rectangle,$this.oldText)
        # ↑ Broken; Opened PowerShell/issues/18239 in response 
        (Get-Host).UI.RawUI.SetBufferContents([System.Management.Automation.Host.Coordinates]::new($renderPadX,$renderPadY),$this.oldText)
        [System.Console]::SetCursorPosition($this.originalCursorPosition.Item1,$this.originalCursorPosition.Item2)
    }

}