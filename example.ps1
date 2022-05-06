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
[Flags()] enum Stat {
    Strength=1
    Dexterity=2
    Constitution=4
    Intelligence=8
    Wisdom=16
    Charisma=32
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
        $this.Modifier = [System.Math]::Round(($this.Value - 10) / 2)
    }
    [void]IncreaseValue([int]$Amount) {
        $this.Value+=$Amount
        $this.Modifier = [System.Math]::Round(($this.Value - 10) / 2)
    }
    [void]Decrease([int]$Amount) {
        $this.Value-=$Amount
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
        $this.Strength = [ActionableStat]::new("Strength",$Strength)
        $this.Dexterity = [ActionableStat]::new("Dexterity",$Dexterity)
        $this.Constitution = [ActionableStat]::new("Constitution",$Constitution)
        $this.Intelligence = [ActionableStat]::new("Intelligence",$Intelligence)
        $this.Wisdom = [ActionableStat]::new("Wisdom", $Wisdom)
        $this.Charisma = [ActionableStat]::new("Charisma",$Charisma)
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
                    $this.Effects = $this.Effects | Where-Object {$_.SourceObject -ne $Effect.SourceObject}
            }
        }
    }
    hidden [void]CalculateLevelIncrement() {
        #temp formula plugins
        [int]$MonsterXP=45 #Average experience granted by base monster, TBD by location
        [int]$Difficulty=1 #Difficulty factor (reference model starts an exponential increase at ~30), leaving at 1 for now
        [int]$ReductionFactor=1 #Difficulty factor reduction, completely TBD, needs to be fine-tuned
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


    Creature (
        [string]$Name,
        [int]$Strenth,
        [int]$Vitality,
        [int]$Level
    ) {
        $this.Name = $Name;
        $this.Stats = [StatBlock]::new($Strenth, $Vitality, $Level)
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
$obj=[StatBlock]::new(10, 10, 10, 10, 10, 10, 1)
#$obj = [Stat]::new("Strength",15)  
#$b=[Stat]::new("Strength",2,"Race - Orc")
#$d=[Stat]::new("Strength",2,"Race - Orc")
#$c=[Stat]::new("Strength",2,"Class - Fighter")
#$obj.AddBonus($b)
#$obj.AddBonus($d)
#$obj.AddBonus($c)
$obj