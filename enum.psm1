<#
# File: enum.psm1
# Created: Monday October 3rd 2022
# Author: Nick Strickland
# -----
# Last Modified: Monday, 3rd October 2022 10:01:08 pm
# ----
# Copright 2022 Nick Strickland, nsstrickland@outlook.com>>
# GNU General Public License v3.0 only - https://www.gnu.org/licenses/gpl-3.0-standalone.html
#>

# Stats

[Flags()] enum Stat {
    Strength=1;
    Dexterity=2;
    Constitution=4;
    Intelligence=8;
    Wisdom=16;
    Charisma=32;
}

# Effects
enum EffectSource {
    Race=0;
    Class=1;
    Equipment=2;
    Spell=3
    Disease=4
}

# Items
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

# Misc
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