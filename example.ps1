<#
# File: example.ps1
# Created: Tuesday June 25th 2019
# Author: nsstrickland
# -----
# Last Modified: Sunday, 14th August 2022 1:29:59 am
# ----
# .DESCRIPTION: PowerCrawl
#
#>

#Requires -Version 7.2

# TODO: Rework the effects system... it's a little too complicated at this point, can probably be simplified.
# We settled on full-text based
# Figure out movement and construct a command interpreter
# Construct basic map
# Populate map with basics:
#  - Monsters
#  - Lootable containers
#  - Obstacles (walls, trees, rocks)
#  - 

#Statistic Base Class
#TODO: Determine how skills fit into the mix
[Flags()] enum Stat {
    Strength=1;
    Dexterity=2;
    Constitution=4;
    Intelligence=8;
    Wisdom=16;
    Charisma=32;
}
[Flags()] enum Direction {
    North=1;
    South=2;
    East=4;
    West=8;
    Northeast=16;
    Northwest=32;
    Southeast=64;
    Southwest=128;
}

class ActionableStat {
    [stat]$Name
    [int]$Value;
    [int]$Modifier;

    ActionableStat() {
        $this.Name = "Undefined"
        $this.Value = 0
    }
    ActionableStat (
        [string]$Name,
        [int]$Value
    ) {
        $this.Name = $Name;
        $this.Value = $Value
        $this.Modifier = [System.Math]::Round(($Value - 10) / 2)
    }

    [string]ToString() {
        if ( $this.Modifier -gt -1 ) {
            $retMod = [string]'+' + $this.Modifier
        }
        else {
            $retMod = [string]$this.Modifier
        }
        return ([string]$this.Value+' (' + $retMod + ')')
    }
    [void]IncrementValue() {
        $this.Value++
        $this.RefreshModifier()
    }
    [void]IncreaseValue([int]$Amount) {
        $this.Value+=$Amount
        $this.RefreshModifier()
    }
    [void]DecreaseValue([int]$Amount) {
        $this.Value-=$Amount
        $this.RefreshModifier()
    }
    [void]RefreshModifier() {
        $this.Modifier = [System.Math]::Round(($this.Value - 10) / 2)
    }
    [int]AbilityCheck() {
        [int]$retValue = (Get-Random -Minimum 1 -Maximum 20) + $this.Modifier
        return $retValue
    }
}
enum EffectSource {
    Race=0;
    Class=1;
    Equipment=2;
    Spell=3
    Disease=4
}
class Effect {
    [string]$Name                   # Name of Effect
    [EffectSource]$Source           # Source of effect, for easy sorting
    hidden [PSObject]$SourceObject  # Source object for easy callbacks/removal
    [string]$Description            # Description of effect
}
class StatEffect : Effect {
    [Stat]$Stat
    [int]$Value                     # Numerical value to alter target statistic

    StatEffect (
        [string]$Name,
        [Stat]$Stat,
        [int]$Value,
        [EffectSource]$Source,
        [PSObject]$SourceObject,
        [string]$Description
    ) {
        $this.Name = $Name;
        $this.Value = $Value;
        $this.Stat = $Stat;
        $this.Source = $Source;
        $this.SourceObject = $SourceObject;
        $this.Description = $Description;
    }
    [string]ToString() {
        if ($this.Value -ge 0) {$retValue="+"+$this.Value} else {$retValue=$this.Value}
        return (-join $this.Stat.ToString()[0..2]+$retValue)
    }
}

class StatBlock {
    [ActionableStat]$Strength;
    [ActionableStat]$Dexterity;
    [ActionableStat]$Constitution;
    [ActionableStat]$Intelligence;
    [ActionableStat]$Wisdom;
    [ActionableStat]$Charisma;
    [int]$Level;
    [int]$AbilityScorePoints        # Points from leveling that may be allocated to any ability score
    [int]$Experience;
    [int]$LevelIncrement;           # The experience total at which the character will level up; TODO: Incorporate location?
    [psobject[]]$Effects;
    StatBlock(
        [int]$Strength,
        [int]$Dexterity,
        [int]$Constitution,
        [int]$Intelligence,
        [int]$Wisdom,
        [int]$Charisma,
        [int]$Level
    ) {
        $this.Strength = [ActionableStat]::new([Stat]"Strength",$Strength)
        $this.Dexterity = [ActionableStat]::new([Stat]"Dexterity",$Dexterity)
        $this.Constitution = [ActionableStat]::new([Stat]"Constitution",$Constitution)
        $this.Intelligence = [ActionableStat]::new([Stat]"Intelligence",$Intelligence)
        $this.Wisdom = [ActionableStat]::new([Stat]"Wisdom", $Wisdom)
        $this.Charisma = [ActionableStat]::new([Stat]"Charisma",$Charisma)
        $this.Level = $Level
        $this.CalculateLevelIncrement()
    }
    [string]ToString() {return "test"}
    [bool]AddExp($XpToAdd) {
        $this.Experience += $XpToAdd;
        if ( $this.Experience -ge $this.LevelIncrement) {
            $this.Level++;
            #if (4,8,12,15,19 -contains $this.Level) {$this.AbilityScorePoints+=2} #5e Ability Score increases
            $this.CalculateLevelIncrement()
            return $true;
        }
        else {
            return $false;
        }
    }
    [void]AddEffect($Effect) {
        switch ($Effect.GetType().name) {
            "StatEffect" {
                [Stat].GetEnumValues() | ForEach-Object -Process {
                    if ($Effect.Stat -band $_) {
                        $this.$_.IncreaseValue($Effect.Value)
                        $this.Effects+=[StatEffect]::new($Effect.Name,$_,$Effect.Value,$Effect.Source,$Effect.SourceObject,$Effect.Description)
                    }
                }
            }
        }
    }
    [void]RemoveEffect($Effect) {
        switch ($Effect.GetType().name) {
            "StatEffect" {
                [Stat].GetEnumValues() | ForEach-Object -Process {
                    if ($Effect.Stat -band $_) {
                        $this.$_.DecreaseValue($Effect.Value)
                        $this.Effects = $this.Effects | Where-Object {$_.SourceObject -ne $Effect.SourceObject}
                    }
                }
            }
        }
    }
    hidden [void]CalculateLevelIncrement() {
        #temp formula plugins
        [int]$MonsterXP=45 #Average experience granted by base monster, TBD by location
        [int]$Difficulty=1 #Difficulty factor (reference model starts an exponential increase at ~30), leaving at 1 for now
        [double]$ReductionFactor=0.5 #Difficulty factor reduction, completely TBD, needs to be fine-tuned
        $this.LevelIncrement = (((8 * $this.Level) + ($Difficulty * $this.Level)) * ($MonsterXP * $this.Level) * ($ReductionFactor * $this.Level))
    }
}
enum ItemRarity {
    Poor = 0;       # Grey name
    Common = 1;     # White name
    Uncommon = 2;   # Green name
    Rare = 3;       # Blue name
    Epic = 4;       # Purple name
    Legendary = 5;  # Orange name
}
enum EquipmentClass {
    Head = 0;
    Shoulder = 1;
    Chest = 2;
    Hands = 3;
    Waist = 4;
    Legs = 5;
    Feet = 6;
    Back = 7;
    Neck = 8;
    Fingers = 9;
}
class Item {
    [string]$Name;
    [ItemRarity]$Rarity;
    [string]$Description;
    [string]$Lore;
    Item ( [string]$Name, [ItemRarity]$Rarity, [string]$Description, [string]$Lore ) {
        $this.Name = $Name
        $this.Rarity = $Rarity
        $this.Description = $Description
        $this.Lore = $Lore
    }
    Item () {
        $this.Name = "Undefined"
        $this.Description = "Undefined"
        $this.Lore = "Undefined"
        $this.Rarity = [ItemRarity]0
    }
}
class Equipment:Item {
    [PSObject[]]$Effects
}
#And now for the actual creatures
class Creature {
    [string]$Name;
    [StatBlock]$StatBlock;
    [Tile]$Location;

    Creature (
        [string]$Name,
        [int]$Level
    ) {
        $this.Name = $Name;
        $this.StatBlock = [StatBlock]::new(10,10,10,10,10,10,$Level)
    }
    
    [void]EquipItem([Weapon]$ItemToAdd) {
        #method to equip an item
        $this.EquippedWeapon = $ItemToAdd;
    }
    [void]UnEquipItem() {
        $this.EquippedWeapon = $null
    }
    [ActionEvent]Attack([Creature]$target) {
        #method to initiate an attack, will equip "fist" item if there's no weapon equipped
        if (!$this.EquippedWeapon) {
            $this.EquippedWeapon = [Weapon]::new("Fist", 5, 2)
        }
        return [ActionEvent]::new($this, $target, $this.EquippedWeapon)
    }
    [string]ToString() {
        return ($this.Name + "hp:" + $this.Health)
    }
    [bool]Move(
        [Direction]$Direction
        ) {
            if (-not $this.Location) {
                return $False
            } else {
                try {
                    $this.Location.MoveCreature($this,$Direction)
                    return $true
                }
                catch {
                    return $False
                }
            }
    }
}
#Event for attacks-- it will act on both the target and the source, modifying health and exp
class ActionEvent {
    [Creature]$Source
    [Creature]$Target
    [int]$DamageDealt

    ActionEvent(
        [Creature]$Source,
        [Creature]$Target,
        [Weapon]$Weapon) {
        $this.Source = $Source;
        $this.Target = $Target;
        $this.DamageDealt = Get-Random -Minimum ($Weapon.Damage / 2) -Maximum $Weapon.Damage;

        $this.Source.Stats.AddExp($this.DamageDealt / 2);
        $this.Target.Health -= $this.DamageDealt;
        if ( $this.Target.Health -le 0 ) {
            Write-Host -ForegroundColor Red -Object ($this.Target.Name + " has died!");
            $this.Source.Stats.AddExp(10)
        }
    }
}
class Weapon {
    [string]$Name;
    [int]$Durability;
    [int]$MaxDurability;
    [int]$Damage
    Weapon ($Name, $Damage, $MaxDurability) {
        $this.Name = $Name;
        $this.Damage = $Damage
        $this.Durability = $MaxDurability;
        $this.MaxDurability = $MaxDurability;
    }
}



class Coordinator {
    # Acts as a notifier to individual objects' AI funcions
}

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

function basicInterpreter {
    $ExitGame=$false
    $substitutes=@{
        left='West'
        right='East'
        up='North'
        down='South'
        go='move'
        walk='move'
        run='move'
        goto='move'
    }
    while ($ExitGame -eq $false) {
        $player=$null;
        $player=Read-Host -Prompt "> "
        $words=$player.Normalize().split(' ')
        foreach ($word in $words) {
            $word=$substitutes[$word]
        }
    }
}

<#
$atk = [Creature]::new("Monster",12,10,1)
$obj.Attack($atk)
#>
#$obj=[StatBlock]::new(10, 10, 10, 10, 10, 10, 1)
#$i=[StatEffect]::new("Witch's Poison",[Stat]::Constitution, -3, [EffectSource]::Disease,"Witch","Poison applied from a witch's blade")
#$obj.AddEffect($i)
#$obj.RemoveEffect($i)
<#
$area=[Area]::new('Tavern','An old tavern',5,5)
(0..4)|%{[char](65+$_)}|%{
    $char=$null;$char=$_
    (0..4)|%{$area.addTile([int]([char]$char-65),$_,$True,"Tile $char$_")}
}

$obj=[Creature]::new("Player",1)
$obj.Location=$area.Tiles[0,0]
$area.Tiles[0,0].Creatures+=$obj
$area.Tiles[4,0].MoveCreature($obj,'East')
#>