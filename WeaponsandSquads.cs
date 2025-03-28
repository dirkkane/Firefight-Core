using (var stream = Cache.OpenCacheReadWrite())
{
    foreach (var tag in Cache.TagCache.FindAllInGroup<TagTool.Tags.Definitions.Scenario>())
    {
        var scnr = Cache.Deserialize<TagTool.Tags.Definitions.Scenario>(stream, tag);
        if (tag.Name.StartsWith("levels\\atlas"))
        {
            
            Console.WriteLine("Modifying Squads: " + tag);
            short elite = -1;
            short elite_major = -1;
            short elite_specops = -1;
            short elite_specops_commander = -1;
            short elite_gold_boss = -1;
            short brute_captain = -1;
            short brute_captain_ultra = -1;
            short brute_captain_major = -1;
            short brute_stalker = -1
            short plasma_rifle = -1;
            short plasma_rifle_red = -1;
            short plasma_rifle_gold = -1;
            short needler = -1;
            short spiker = -1;
            short mauler = -1;
            short carbine = -1;
            short brute_shot = -1;
            short energy_sword = -1;
            foreach (var character in scnr.CharacterPalette)
            {
                if (character.Instance != null)
                {
                    if (character.Instance.Name.Equals("objects\\characters\\elite\\ai\\elite")) elite = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\elite\\ai\\elite_major")) elite_major = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\elite\\ai\\elite_specops")) elite_specops = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\elite\\ai\\elite_specops_commander")) elite_specops_commander = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\elite\\ai\\elite_gold_boss")) elite_gold_boss = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\brute\\ai\\brute_captain") && brute_captain == -1) brute_captain = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\brute\\ai\\brute_captain_ultra")) brute_captain_ultra = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\brute\\ai\\brute_captain_major")) brute_captain_major = (short)scnr.CharacterPalette.IndexOf(character);
                    else if (character.Instance.Name.Equals("objects\\characters\\brute\\ai\\brute_stalker")) brute_stalker = (short)scnr.CharacterPalette.IndexOf(character);
                }
            }
            foreach (var weapon in scnr.WeaponPalette)
            {
                if (weapon.Object != null)
                {
                    if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\plasma_rifle\\plasma_rifle")) plasma_rifle = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\plasma_rifle_red\\plasma_rifle_red")) plasma_rifle_red = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\plasma_rifle\\plasma_rifle_power")) plasma_rifle_gold = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\spike_rifle\\spike_rifle")) spiker = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\pistol\\excavator\\excavator")) mauler = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\pistol\\needler\\needler")) needler = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\covenant_carbine\\covenant_carbine")) carbine = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\support_low\\brute_shot\\brute_shot")) brute_shot = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\melee\\energy_blade\\energy_blade")) energy_sword = (short)scnr.WeaponPalette.IndexOf(weapon);
                }
            }
            foreach (var squad in scnr.Squads)
            {
                foreach (var designerfireteam in squad.DesignerFireteams)
                {
                    var fireteamname = Cache.StringTable.GetString(designerfireteam.Name);
                    var ModuleID = Cache.StringTable.GetString(squad.ModuleId
                    if (fireteamname.StartsWith("1_brute_captain") && ModuleID.StartsWith("sq_sur_covenant"))
                    {
                        foreach (var charactertype in designerfireteam.CharacterType)
                        {
                            if (charactertype.CharacterTypeIndex.Equals(brute_captain)) charactertype.CharacterTypeIndex = elite;
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
            Console.WriteLine("CHARACTER PALETTE INDEXES: ");
            Console.WriteLine("Elite: " + elite);
            Console.WriteLine("Elite Major: " + elite_major);
            Console.WriteLine("Elite SpecOps: " + elite_specops);
            Console.WriteLine("Elite Specops Commander: " + elite_specops_commander);
            Console.WriteLine("Elite Gold Boss: " + elite_gold_boss);
            Console.WriteLine("Brute Captain: " + brute_captain);
            Console.WriteLine("Brute Captain Major: " + brute_captain_major);
            Console.WriteLine("Brute Captain Ultra: " + brute_captain_ultra);
            Console.WriteLine("Brute Stalker: " + brute_stalker
            Console.WriteLine("WEAPON PALETTE INDEXES: ");
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
        Cache.Serialize(stream, tag, scnr);
    }
}