![cover photo](https://github.com/dirkkane/Firefight-Core/blob/dev/assets/preview.png?raw=true)

A firefight mod for ElDewrito 0.7. This is intended to be used as the basis for any firefight mods the community wishes to make. It includes scripts to fix issues that occur out of the box, enhance gameplay, and add some bonus content such as Flood firefight. This repository contains most of the data that you need to build the pak for yourself.

If you're going to use my mod as a basis for yours, please make both of our lives easier and add your changes to the scripts in this repo and build it that way. Don't take the finished compiled pak and add stuff on top of it, it's just going to create issues and cause you to lose your progress at some point.

# How To Build
## Variables
The first thing you need to do is change the following lines at the beginning of `build.cmds` and `buildSmall.cmds`:

At the top where it says `basecache`, replace it with the full path to your clean ElDewrito 0.7 map files (ex. `C:\Users\User\Games\ElDewrito\maps\tags.dat`) 

Next, change the variables as follows:
```
setvariable firefightfolder path
setvariable audiocache path
setvariable shadercache path
```
Replace the word `path` next to `firefightfolder` with the full path to the folder you saved this repository.

Next, replace the word `path` next to `audiocache` and `shadercache` with the directories where you keep your porting caches for ElDewrito. If you do not have these, it is recommended that you create them. To do this, create folders named `shadercache` and `audiocache` wherever you wish and supply those paths to the script, TagTool will handle the rest. You may also download pre-made caches from [here](https://github.com/dirkkane/ElDewrito-Porting-Caches).

**NOTE:** On the first build if you have no pre-existing audio and shader caches, it will take a *very* long time to build so expect to wait a while before it is finished. Once you successfully build the mod your audio and shader caches will be populated and subsequent builds should be considerably faster. It is recommended to use the audio and shader caches from the repo above if you have never compiled this mod before.

## Source Files
This mod works by porting content from Halo 3, Halo 3 ODST, and Halo 3 ODST MCC. You must provide the files needed for this mod yourself and place them in the `source_maps` folder as follows:

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

***DO NOT ASK ME FOR THESE FILES, I WILL NOT PROVIDE THEM.***

## Building
Once you have completed the above steps, run `build.bat` and the mod will build.

# Contact
If you have any questions, please feel free to DM @dirkkane on Discord or ping me in any ElDewrito Discord servers.