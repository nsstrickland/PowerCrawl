<#
# File: example.ps1
# Created: Tuesday June 25th 2019
# Author: nsstrickland
# -----
# Last Modified: Tuesday, 25th June 2019 6:46:08 pm
# ----
# .DESCRIPTION: PowerCrawl
#>

#Statistic Base Class
#TODO: Determine how skills fit into the mix
class Stat {
    [string]$Name;
    [int]$Value;
    [int]$Modifier = [System.Math]::Round(($Value - 10) / 2);

    Stat (
        [string]$Name,
        [int]$Value
    ) {
        $this.Name = $Name;
        $this.Value = $Value
    }
    [string] ToString() {
        if ( $this.Modifier -gt -1 ) {
            $retMod = [string]'+' + $this.Modifier
        }
        else {
            $retMod = [string]$this.Modifier
        }
        return ($this.Name + ' = ' + $this.Value + ' (' + $retMod + ');')
    }

}
class StatBlock {
    [Stat[]]$AbilityScores;
    [int]$Level;
    [int]$Experience;
    [int]$LevelIncrement; #The experience total at which the character will level up; TODO: Incorporate location?
    StatBlock(
        [int]$Strength,
        [int]$Dexterity,
        [int]$Constitution,
        [int]$Intelligence,
        [int]$Wisdom,
        [int]$Charisma,
        [int]$Level
    ) {
        $this.AbilityScores = [Stat[]]@([Stat]::new("Strength",$Strength), [Stat]::new("Dexterity",$Dexterity), [Stat]::new("Constitution",$Constitution), [Stat]::new("Intelligence",$Intelligence), [Stat]::new("Wisdom", $Wisdom), [Stat]::new("Charisma",$Charisma))
        $this.Level = $Level
        #temp formula plugins
        [int]$MonsterXP=45 #Average experience granted by base monster, TBD by location
        [int]$Difficulty=1 #Difficulty factor (reference model starts an exponential increase at ~30), leaving at 1 for now
        [int]$ReductionFactor=1 #Difficulty factor reduction, completely TBD, needs to be fine-tuned
        $this.LevelIncrement = (((8 * $Level) + ($Difficulty * $Level)) * ($MonsterXP * $Level) * ($ReductionFactor * $Level))
    }
    [string]ToString() {return "test"}
    [bool]AddExp($XpToAdd) {
        #returns true or false to tell if we leveled up or not
        $this.Experience += $XpToAdd;
        if ( $this.Experience -ge ($this.Level * $this.LevelIncrement)) {
            $this.Level++;
            $this.Strength += 2;
            $this.Vitality++;
            Write-Host -ForegroundColor Green "You leveled up!"
            return $true;
        }
        else {
            return $false;
        }
    }
}
#And now for the actual creatures
class Creature {
    [string]$Name;
    [StatTable]$Stats;
    [int]$Health;
    [Weapon]$EquippedWeapon;

    Creature (
        [string]$Name,
        [int]$Strenth,
        [int]$Vitality,
        [int]$Level
    ) {
        $this.Name = $Name;
        $this.Stats = [StatTable]::new($Strenth, $Vitality, $Level)
        $this.Health = ($this.Stats.Vitality / 2)
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

<#
$obj=[Creature]::new("Player",12,10,1)
$atk = [Creature]::new("Monster",12,10,1)
$obj.Attack($atk)
#>