# ElDewrito Firefight
A firefight mod for ElDewrito. This repository contains all of the scripts, assets, and other data that you need to modify and build the pak for yourself. Some extra setup is required though, so follow the guide below.

# Configuration
## Variables
The first thing you will need to do is change the following lines at the beginning of `build.cmds` and `buildSmall.cmds`:

```
setvariable firefightfolder path
setvariable audiocache path
setvariable shadercache path
```
Replace the word `path` next to `firefightfolder` with the full directory path to the folder you saved this repository to.
Replace the word `path` next to `audiocache` and `shadercache` with the directories where you keep your porting caches for ElDewrito. If you do not have these, it is recommended that you create them. To do this, create folders named `shadercache` and `audiocache` wherever you wish on your hard drive and supply those paths to the script, TagTool will handle the rest. You may also download pre-made caches from this repository: https://github.com/dirkkane/ElDewrito-Porting-Caches.


## Source Files
This mod works by porting content from the original Xbox 360 version of Halo 3: ODST, you must provide the files needed for this mod yourself and place them in the `source_maps` folder as follows:

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

***DO NOT ASK ME FOR THESE FILES, I WILL NOT PROVIDE THEM.***

## Building
Once you have completed the above steps, open TagTool and run the following command:

`runcommands <path_to_repo>\build.cmds`

**NOTE:** On the first build if you have no pre-existing audio and shader caches, it will take a *very* long time to build so expect to wait a while before it is finished. Once you successfully build the mod your audio and shader caches will be populated and subsequent builds should be considerably faster. 
# Contact
If you have any questions, please feel free to DM @dirkkane on Discord or ping me in the ElDewrito Modpacks Discord server.
