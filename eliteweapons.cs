using (var stream = Cache.OpenCacheReadWrite())
{
    foreach (var tag in Cache.TagCache.FindAllInGroup<TagTool.Tags.Definitions.Scenario>())
    {
        var scnr = Cache.Deserialize<TagTool.Tags.Definitions.Scenario>(stream, tag);
        if (tag.Name.StartsWith("levels\\atlas"))
        {
            if (tag.Name.StartsWith("levels\\atlas"))
            {
                Console.WriteLine("Adding weapons to squads: " + tag);
                short plasma_rifle = -1;
                short plasma_rifle_red = -1;
                short needler = -1;                
                short spiker = -1;
                short mauler = -1;
                foreach (var weapon in scnr.WeaponPalette)
                {
                    if (weapon.Object != null)
                    {
                        if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\plasma_rifle\\plasma_rifle")) plasma_rifle = (short)scnr.WeaponPalette.IndexOf(weapon);
                        else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\plasma_rifle_red\\plasma_rifle_red")) plasma_rifle_red = (short)scnr.WeaponPalette.IndexOf(weapon);
                        else if (weapon.Object.Name.Equals("objects\\weapons\\rifle\\spike_rifle\\spike_rifle")) spiker = (short)scnr.WeaponPalette.IndexOf(weapon);
                        else if (weapon.Object.Name.Equals("objects\\weapons\\pistol\\excavator\\excavator")) mauler = (short)scnr.WeaponPalette.IndexOf(weapon);
                        else if (weapon.Object.Name.Equals("objects\\weapons\\pistol\\needler\\needler")) needler = (short)scnr.WeaponPalette.IndexOf(weapon);
                    }
                }
                foreach (var squad in scnr.Squads)
                {
                    foreach (var designerfireteam in squad.DesignerFireteams)
                    {
                        var fireteamname = Cache.StringTable.GetString(designerfireteam.Name);

                        if (fireteamname.StartsWith("1_brute"))
                        {
                            foreach (var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                            {
                                if (primaryweapon.ItemTypeIndex.Equals(plasma_rifle_red)) primaryweapon.ItemTypeIndex = plasma_rifle;
                                else if (primaryweapon.ItemTypeIndex.Equals(spiker)) primaryweapon.ItemTypeIndex = plasma_rifle;

                            }
                        }
                        else if (fireteamname.StartsWith("4_brute_stealth"))
                        {
                            foreach(var primaryweapon in designerfireteam.InitialPrimaryWeapon)
                            {
                                if (primaryweapon.ItemTypeIndex.Equals(mauler)) primaryweapon.ItemTypeIndex = needler;
                            }
                        }
                    }
                }
                Console.WriteLine("Plasma Rifle: " + plasma_rifle);
                Console.WriteLine("Plasma Rifle Red: " + plasma_rifle_red);
                Console.WriteLine("Needler: " + needler);
                Console.WriteLine("Spiker: " + spiker);
                Console.WriteLine("Mauler: " + mauler);
            }
        }
        Cache.Serialize(stream, tag, scnr);
    }
}