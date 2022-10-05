<#
# File: Items.psm1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Monday, 3rd October 2022 10:01:20 pm
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>
Using  module ./enum.psm1

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