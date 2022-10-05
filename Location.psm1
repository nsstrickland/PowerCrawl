<#
# File: Location.psm1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Monday, 3rd October 2022 10:02:54 pm
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>

Using module ./Character.psm1

class Tile {
    [Creature[]]$Creatures
    [Area]$ParentArea
    [hashtable]$Coordinates
    [bool]$Traversible
    [string]$Description

    Tile (
        [Area]$Area,
        [Hashtable]$Coordinates,
        [bool]$Traversible,
        [string]$Description
    ) {
        $this.ParentArea=$Area
        $this.Coordinates=$Coordinates
        $this.Traversible=$Traversible
        $this.Description=$Description
    }
    [string]ToString() {
        return [string]([string]$this.ParentArea.Name+": "+[string]$this.Coordinates.x+","+[string]$this.Coordinates.Y)
    }
    [bool]MoveCreature(
        [Creature]$Creature,
        [Direction]$Direction
    ) {
        if ($this.Creatures -notcontains $Creature) {
            return $False
        }
        $X=$null;$Y=$null
        switch ($Direction) {
            'North'     {$X=0;$Y=-1};
            'South'     {$X=0;$Y=1};
            'East'      {$X=1;$Y=0};
            'West'      {$X=-1;$Y=0};
            'Northeast' {$X=1;$Y=-1};
            'Northwest' {$X=-1;$Y=-1};
            'Southeast' {$X=1;$Y=1};
            'Southwest' {$X=-1;$Y=1};
        }
        if ( ($null -ne $X) -and ($null -ne $Y)) {
            $movingTo=$this.ParentArea.Tiles[($this.Coordinates.X+$X),($this.Coordinates.Y+$Y)]
            if ($movingTo.Traversible -eq $True) {
                try { 
                    $this.Creatures = $this.Creatures | Where-Object {$_ -ne $Creature}
                    $movingTo.Creatures+=$Creature
                    $Creature.Location=$movingTo
                    return $True
                }
                catch {
                    Write-Host
                    return $False
                }
            } else {
                return $False
            }
        } else {
            #Something went wrong
            return $false
        }
    }
}

class Area {
    # Grouping of tiles, can be held inside of tiles recursively
    [string]$Name
    [string]$Description
    
    [System.Collections.Hashtable]$Bounds=@{X=5;Y=5}
    [Object[,]]$Tiles
    [Zone]$ParentZone

    Area ( #Creates a blank area with defined bounds
        [string]$Name,
        [string]$Description,
        [int]$BoundsX,
        [int]$BoundsY
    ) {
        $this.Name = $Name
        $this.Description = $Description
        $this.Bounds=@{X=$BoundsX;Y=$BoundsY}
        $this.Tiles=New-Object 'object[,]' $BoundsX,$BoundsY
    }
    [string]ToString() {
        return $this.Name;
    }
    [bool]addTile(
        [int]$X,
        [int]$Y,
        [bool]$Traversible,
        [string]$Description
    ) {
        try {
            $this.Tiles[$X,$Y]=[Tile]::new($this,@{X=${X};Y=${Y}},$Traversible,$Description)
            return $True
        }
        catch {
            Write-Output $_
            return $false

        }
    }
}

class Zone {
    #Grouping of Areas
}