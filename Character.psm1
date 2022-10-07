<#
# File: example.ps1
# Created: Tuesday June 25th 2019
# Author: nsstrickland
# -----
# Last Modified: Wednesday, 5th October 2022 8:53:47 pm
# ----
# .DESCRIPTION: PowerCrawl
#
#>

#Requires -Version 7.2
Using module "./enum.psm1"
Using module "./Stats.psm1"
Using module "./Items.psm1"

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
        return $this.Name
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