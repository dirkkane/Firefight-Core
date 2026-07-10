@ECHO off

set "configFile=.env"
for /f "delims=" %%i in (%configFile%) do (
    call %%i
)

pushd tagtool

(
	echo setvariable firefightfolder %workingdir%
	type ..\build.cmds

) |tagtool.exe %basecache%

popd
pause