![cover photo](https://raw.githubusercontent.com/dirkkane/Firefight-Core/refs/heads/main/assets/preview.png)

A firefight mod for ElDewrito 0.7. This is intended to be used as the basis for any firefight mods the community wishes to make. It includes scripts to fix issues that occur out of the box, enhance gameplay, and add some bonus content such as Flood firefight. Download completed builds from [ZGAF Fileshare](https://fileshare.zgaf.io/api_v2/modview?modId=112) or the [ElDewrito Modding Discord server.](https://discord.gg/KGZ6uGXX)

If you're going to use my mod as a basis for yours, please make both of our lives easier and add your changes to the scripts in this repo and build it that way. Don't take the finished compiled pak and add stuff on top of it, it's just going to create issues and cause you to lose your progress at some point.

# How To Build
## Variables
Change the following lines at the beginning of `build.cmds` and `buildMaps.cmds`:

```
basecache

setvariable firefightfolder path
```

Replace `basecache` with the full path to your clean ElDewrito 0.7 map files <br> (ex. `C:\Users\User\Games\ElDewrito\maps\tags.dat`).

Then replace the word `path` next to `firefightfolder` with the full path to the folder where you saved this repository.

## Source Files
This mod works by porting content from Xbox 360 versions of Halo 3 and Halo 3: ODST as well as the MCC PC version of Halo 3: ODST. Place the files listed below into the respective subfolders as shown.
> [!IMPORTANT]  
> You must provide the files listed below from your own legally obtained and backed up copies of these games.
> <br> ***DO NOT ASK ME FOR THESE FILES, I WILL NOT PROVIDE THEM.***

`source_maps\odst`:
```
h100.map
l200.map
l300.map
sc100.map
sc110.map
sc120.map
sc130.map
sc140.map
campaign.map
mainmenu.map
shared.map
```

`source_maps\h3`:
```
110_hc.map
campaign.map
mainmenu.map
shared.map
```

`source_maps\mcc`:
```
sc130.map
campaign.map
shared.map
```

`source_maps\fmod`:
```
paste the FMOD sounds from Halo 3 ODST MCC into this folder.
```

## Patch Source Maps (OPTIONAL)
In order to save space, there are patches for the source maps included in the `assembly_patches` folder. These remove BSP references in the scenario tags so only the BSPs used in firefight are ported into the mod. <br> Open [Assembly](https://github.com/XboxChaos/Assembly), click `Create, Apply, or Poke Patch...`, then follow the instructions on screen for every map: <br> ![Assembly Patcher Screenshot](https://raw.githubusercontent.com/dirkkane/Firefight-Core/refs/heads/main/assembly_patches/assembly.png)

## Building
Once you have completed the above steps run `buildMaps.bat`, this will create a mod package in the `paks` folder that contains most of the ported data from Halo 3: ODST to save time on future builds. When that finishes run `build.bat` to create the actual firefight mod, the complete mod package will be saved to the mods folder in your ElDewrito installation.
> [!TIP]
> Any subsequent builds of the mod only require `build.bat` to be run, though it's recommended to run `buildMaps.bat` again after major TagTool updates.

# Contact
If you have any questions, please feel free to DM @dirkkane on Discord or ping me in any ElDewrito Discord servers.

