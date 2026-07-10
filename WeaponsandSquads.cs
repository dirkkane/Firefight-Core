using (var stream = Cache.OpenCacheReadWrite())
{
    foreach (var tag in Cache.TagCache.FindAllInGroup<TagTool.Tags.Definitions.Scenario>())
    {
        var scenario = Cache.Deserialize<TagTool.Tags.Definitions.Scenario>(stream, tag);
        if (tag.Name.StartsWith("levels\\atlas"))
        {
            Console.WriteLine("\nModifying Squads: " + tag);

            // Initialize all needed indexes as -1 (invalid index, game assumes null if assigned)
            short elite = -1;
            short elite_major = -1;
            short elite_specops = -1;
            short elite_specops_commander = -1;
            short elite_gold_boss = -1;
            short brute = -1;
            short brute_captain = -1;
            short brute_captain_ultra = -1;
            short brute_captain_major = -1;
            short brute_stalker = -1;
            short plasma_rifle = -1;
            short plasma_rifle_red = -1;
            short plasma_rifle_gold = -1;
            short needler = -1;
            short spiker = -1;
            short mauler = -1;
            short carbine = -1;
            short brute_shot = -1;
            short energy_sword = -1;

            // Get indexes for all required character tags in the current scenario
            foreach (var character in scenario.CharacterPalette)
            {
                switch (character.Instance?.Name)
                {
                    case "objects\\characters\\elite\\ai\\elite":
                        elite = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\elite\\ai\\elite_major":
                        elite_major = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\elite\\ai\\elite_specops":
                        elite_specops = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\elite\\ai\\elite_specops_commander":
                        elite_specops_commander = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\elite\\ai\\elite_gold_boss":
                        elite_gold_boss = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\brute\\ai\\brute":
                        brute = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\brute\\ai\\brute_captain":
                        if (brute_captain == -1) // Only assign variable to the found index if it hasn't already been assigned. Protects against duplicate palette entries i'm assuming, don't remember which maps have this problem.
                        {
                            brute_captain = (short)scenario.CharacterPalette.IndexOf(character);
                        }
                        break;
                    case "objects\\characters\\brute\\ai\\brute_captain_ultra":
                        brute_captain_ultra = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\brute\\ai\\brute_captain_major":
                        brute_captain_major = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case "objects\\characters\\brute\\ai\\brute_stalker":
                        brute_stalker = (short)scenario.CharacterPalette.IndexOf(character);
                        break;
                    case null:
                        break;
                    default:
                        break;
                }
            }

            // Get indexes for all required weapon tags in the current scenario
            foreach (var weapon in scenario.WeaponPalette)
            {
                switch (weapon.Object?.Name)
                {
                     case "objects\\weapons\\rifle\\plasma_rifle\\plasma_rifle":
                         plasma_rifle = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\rifle\\plasma_rifle_red\\plasma_rifle_red":
                         plasma_rifle_red = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\rifle\\plasma_rifle\\plasma_rifle_power":
                         plasma_rifle_gold = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\rifle\\spike_rifle\\spike_rifle":
                         spiker = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\pistol\\excavator\\excavator":
                         mauler = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\pistol\\needler\\needler":
                         needler = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\rifle\\covenant_carbine\\covenant_carbine":
                         carbine = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\support_low\\brute_shot\\brute_shot":
                         brute_shot = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case "objects\\weapons\\melee\\energy_blade\\energy_blade":
                         energy_sword = (short)scenario.WeaponPalette.IndexOf(weapon);
                         break;
                     case null:
                         break;
                     default:
                         break;
                }
            } 

            // Replace palette indexes referenced by squads with the desired new weapon / character
            foreach (var squad in scenario.Squads)
            {
                foreach (var designerfireteam in squad.DesignerFireteams)
                {
                    var fireteamname = Cache.StringTable.GetString(designerfireteam.Name);
                    var Template = Cache.StringTable.GetString(squad.Template);
                    if (Template.StartsWith("sq_sur_covenant") || Template.StartsWith("sq_sur_brute_pack"))
                    {
                        foreach (var charactertype in designerfireteam.CharacterType)
                        {
                            if (charactertype.CharacterTypeIndex.Equals(brute_captain)) charactertype.CharacterTypeIndex = elite;
                            else if (charactertype.CharacterTypeIndex.Equals(brute)) charactertype.CharacterTypeIndex = elite;
                            else if (charactertype.CharacterTypeIndex.Equals(brute_captain_major)) charactertype.CharacterTypeIndex = elite_major;
                            else if (charactertype.CharacterTypeIndex.Equals(brute_captain_ultra)) charactertype.CharacterTypeIndex = elite_specops_commander;
                        }
                    
                        foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                        {
                            if (primaryweapon.ItemTypeIndex.Equals(plasma_rifle_red)) primaryweapon.ItemTypeIndex = plasma_rifle;
                            else if (primaryweapon.ItemTypeIndex.Equals(spiker)) primaryweapon.ItemTypeIndex = plasma_rifle;
                        }
                    }
                    else if (fireteamname.StartsWith("4_brute_stealth"))
                    {
                        foreach (var charactertype in designerfireteam.CharacterType)
                        {
                            if (charactertype.CharacterTypeIndex.Equals(brute_stalker)) charactertype.CharacterTypeIndex = elite_specops;
                        }
                        foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                        {
                            if (primaryweapon.ItemTypeIndex.Equals(mauler)) primaryweapon.ItemTypeIndex = plasma_rifle_gold;
                        }
                    }
                    else if (fireteamname.StartsWith("1_bugger_captain") || fireteamname.StartsWith("4_buggers") || fireteamname.StartsWith("3_buggers"))
                    {
                        foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                        {
                            if (primaryweapon.ItemTypeIndex.Equals(plasma_rifle_red)) primaryweapon.ItemTypeIndex = plasma_rifle;
                        }
                    }
                    foreach (var charactertype in designerfireteam.CharacterType)
                    {
                        if (charactertype.CharacterTypeIndex.Equals(elite) || charactertype.CharacterTypeIndex.Equals(elite_major) || charactertype.CharacterTypeIndex.Equals(elite_specops_commander))
                        {
                            foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                            {
                                if (primaryweapon.ItemTypeIndex.Equals(brute_shot)) primaryweapon.ItemTypeIndex = carbine;
                            }
                        }
                    }
                    //else if (fireteamname.StartsWith("1_hammer"))
                    //{
                    //    designerfireteam.characterblock = new List<TagRef

                }
            }
            
            // Print found indexes for reference by modder
            Console.WriteLine("\nCHARACTER PALETTE INDEXES:");
            Console.WriteLine("Elite: " + elite);
            Console.WriteLine("Elite Major: " + elite_major);
            Console.WriteLine("Elite SpecOps: " + elite_specops);
            Console.WriteLine("Elite Specops Commander: " + elite_specops_commander);
            Console.WriteLine("Elite Gold Boss: " + elite_gold_boss);
            Console.WriteLine("Brute Captain: " + brute_captain);
            Console.WriteLine("Brute Captain Major: " + brute_captain_major);
            Console.WriteLine("Brute Captain Ultra: " + brute_captain_ultra);
            Console.WriteLine("Brute Stalker: " + brute_stalker);

            Console.WriteLine("\nWEAPON PALETTE INDEXES:");
            Console.WriteLine("Plasma Rifle: " + plasma_rifle);
            Console.WriteLine("Plasma Rifle Red: " + plasma_rifle_red);
            Console.WriteLine("Plasma Rifle PWR: " + plasma_rifle_gold);
            Console.WriteLine("Needler: " + needler);
            Console.WriteLine("Spiker: " + spiker);
            Console.WriteLine("Mauler: " + mauler);
            Console.WriteLine("Brute Shot: " + brute_shot);
            Console.WriteLine("Carbine: " + carbine);
            Console.WriteLine("Energy Sword: " + energy_sword);
        }
        Cache.Serialize(stream, tag, scenario);
    }
}