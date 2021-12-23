<#
# File: example.ps1
# Created: Tuesday June 25th 2019
# Author: nsstrickland
# -----
# Last Modified: Tuesday, 25th June 2019 6:46:08 pm
# ----
# .DESCRIPTION: PowerCrawl
#>

#"Creature" section 
 #Start off with a basis for `all` creatures: their statistics
class Stat {
    [string]$Name;
    [int]$Value;
    [int]$Modifier=[System.Math]::Round(($Value-10)/2);
    Stat (
        [string]$Name,
        [int]$Value
    ) {
        $this.Name=$Name;
        $this.Value=$Value
    }
    [string] ToString() {
        return ($this.Name+'='+$this.Value+' [ '+$this.Modifier+' ];')
    }
    

    }

}
 class StatTable {
    [int]$Strength;
    [int]$Vitality;
    [int]$Experience;
    [int]$Level;
    hidden [int]$LevelIncrement;
    StatTable() { #constructor if we want the defaults
        $this.Strength=10
        $this.Vitality=5;
        $this.Experience = 0;
        $this.Level = 1;
        $this.LevelIncrement = 50;
    }
    StatTable( #constructor if we don't want the defaults
        [int]$Strength,
        [int]$Vitality,
        [int]$Level
    ){
        $this.Strength = $Strength;
        $this.Vitality = $Vitality;
        $this.Level = $Level
        $this.LevelIncrement = 50;
        $this.Experience = (($level*$this.LevelIncrement) - $this.LevelIncrement);
    }
    [string]ToString(){
        return ("str=" + $this.Strength + ", vit=" + $this.Vitality + ", lvl=" +$this.Level)
    }
    [bool]AddExp($XpToAdd){ #returns true or false to tell if we leveled up or not
        $this.Experience+=$XpToAdd;
        if ( $this.Experience -ge ($this.Level*$this.LevelIncrement)) {
            $this.Level++;
            $this.Strength+=2;
            $this.Vitality++;
            Write-Host -ForegroundColor Green "You leveled up!"
            return $true;
        } else {
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
        $this.Stats = [StatTable]::new($Strenth,$Vitality,$Level)
        $this.Health = ($this.Stats.Vitality/2)
    }
    
    [void]EquipItem([Weapon]$ItemToAdd) { #method to equip an item
        $this.EquippedWeapon = $ItemToAdd;
    }
    [void]UnEquipItem() {
        $this.EquippedWeapon = $null
    }
    [ActionEvent]Attack([Creature]$target){ #method to initiate an attack, will equip "fist" item if there's no weapon equipped
        if (!$this.EquippedWeapon) {
            $this.EquippedWeapon = [Weapon]::new("Fist",5,2)
        }
        return [ActionEvent]::new($this,$target,$this.EquippedWeapon)
    }
    [string]ToString(){
        return ($this.Name + "hp:"+$this.Health)
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
        $this.DamageDealt = Get-Random -Minimum ($Weapon.Damage/2) -Maximum $Weapon.Damage;

        $this.Source.Stats.AddExp($this.DamageDealt/2);
        $this.Target.Health-=$this.DamageDealt;
        if ( $this.Target.Health -le 0 ) {
            Write-Host -ForegroundColor Red -Object ($this.Target.Name+" has died!");
            $this.Source.Stats.AddExp(10)
        }
    }
}
class Weapon {
    [string]$Name;
    [int]$Durability;
    [int]$MaxDurability;
    [int]$Damage
    Weapon ($Name,$Damage,$MaxDurability) {
        $this.Name = $Name;
        $this.Damage = $Damage
        $this.Durability=$MaxDurability;
        $this.MaxDurability=$MaxDurability;
    }
}

<#
$obj=[Creature]::new("Player",12,10,1)
$atk = [Creature]::new("Monster",12,10,1)
$obj.Attack($atk)
#>         