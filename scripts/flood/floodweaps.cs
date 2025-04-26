using (var stream = Cache.OpenCacheReadWrite())
{
    foreach (var tag in Cache.TagCache.FindAllInGroup<TagTool.Tags.Definitions.Scenario>())
    {
        var scnr = Cache.Deserialize<TagTool.Tags.Definitions.Scenario>(stream, tag);
        if (tag.Name.StartsWith("levels\\dirk\\flood"))
        {
            Console.WriteLine ("\nModifying Flood Squads: " + tag);
            short flak_cannon = -1;
            short grav_hammer = -1;
            short flood_tank = -1;
            foreach (var weapon in scnr.WeaponPalette)
            {
                if (weapon.Object != null)
                {
                    if (weapon.Object.Name.Equals("objects\\weapons\\support_high\\flak_cannon\\flak_cannon")) flak_cannon = (short)scnr.WeaponPalette.IndexOf(weapon);
                    else if (weapon.Object.Name.Equals("objects\\weapons\\melee\\gravity_hammer\\gravity_hammer")) grav_hammer = (short)scnr.WeaponPalette.IndexOf(weapon);
                }   
            }
            foreach (var character in scnr.CharacterPalette)
            {
                if (character.Instance != null)
                {
                    if (character.Instance.Name.Equals("objects\\characters\\flood_tank\\ai\\flood_pureform_tank")) flood_tank = (short)scnr.CharacterPalette.IndexOf(character);
                }
            }
            foreach (var squad in scnr.Squads)
            {
                foreach (var designerfireteam in squad.DesignerFireteams)
                {
                    foreach (var charactertype in designerfireteam.CharacterType)
                    {
                      if (charactertype.CharacterTypeIndex.Equals(flood_tank))
                        {
                            foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                            {
                                if (primaryweapon.ItemTypeIndex.Equals(flak_cannon) || primaryweapon.ItemTypeIndex.Equals(grav_hammer)) primaryweapon.ItemTypeIndex = -1;
                            }
                        }
                    }
                }
                
            }
        Console.WriteLine("\nCHARACTER PALETTE INDEXES: \n");
        Console.WriteLine("Flood Tank: " + flood_tank);

        Console.WriteLine("\nWEAPON PALETTE INDEXES: \n");
        Console.WriteLine("Fuel Rod: " + flak_cannon);
        Console.WriteLine("Gravity Hammer: " + grav_hammer);
        }
        Cache.Serialize(stream, tag, scnr);
    }
}