using (var stream = Cache.OpenCacheReadWrite())
{
    foreach (var tag in Cache.TagCache.FindAllInGroup<TagTool.Tags.Definitions.Scenario>())
    {
        var scnr = Cache.Deserialize<TagTool.Tags.Definitions.Scenario>(stream, tag);
        if (tag.Name.StartsWith("levels\\atlas"))
        {
            Console.WriteLine("Adding elites to squads: " + tag);
            short elite = -1;
            short elite_major = -1;
            short elite_specops = -1;
            short elite_specops_commander = -1;
            short elite_gold_boss = -1;
            short brute_captain = -1;
            short brute_captain_ultra = -1;
            short brute_captain_major = -1;
            short brute_stalker = -1;
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
            foreach (var squad in scnr.Squads)
            {
                foreach (var designerfireteam in squad.DesignerFireteams)
                {
                    var fireteamname = Cache.StringTable.GetString(designerfireteam.Name);

                    if (fireteamname.StartsWith("1_brute"))
                    {
                        foreach (var charactertype in designerfireteam.CharacterType)
                        {
                            if (charactertype.CharacterTypeIndex.Equals(brute_captain)) charactertype.CharacterTypeIndex = elite;
                            else if (charactertype.CharacterTypeIndex.Equals(brute_captain_major)) charactertype.CharacterTypeIndex = elite_major;
                            else if (charactertype.CharacterTypeIndex.Equals(brute_captain_ultra)) charactertype.CharacterTypeIndex = elite_specops_commander;

                        }
                    }

                    else if (fireteamname.StartsWith("4_brute_stealth"))
                    {
                        foreach (var charactertype in designerfireteam.CharacterType)
                        {
                            if (charactertype.CharacterTypeIndex.Equals(brute_stalker)) charactertype.CharacterTypeIndex = elite_specops;
                        }
                    }

                   //else if (fireteamname.StartsWith("1_hammer"))
                   //{
                   //    designerfireteam.CharacterType.;
                   //}

                }
            }
            Console.WriteLine("Elite: " + elite);
            Console.WriteLine("Elite Major: " + elite_major);
            Console.WriteLine("Elite SpecOps: " + elite_specops);
            Console.WriteLine("Elite Specops Commander: " + elite_specops_commander);
            Console.WriteLine("Elite Gold Boss: " + elite_gold_boss);
            Console.WriteLine("Brute Captain: " + brute_captain);
            Console.WriteLine("Brute Captain Major: " + brute_captain_major);
            Console.WriteLine("Brute Captain Ultra: " + brute_captain_ultra);
            Console.WriteLine("Brute Stalker: " + brute_stalker);
        }
        Cache.Serialize(stream, tag, scnr);
    }
}