#!/bin/bash
echo "Time-Tracker: Build started."

echo "Time-Tracker: Compile Script into executable."
if ! which Aut2Exe ; then
    echo "Time-Tracker: AutoIt Compiler could not be found. Exiting."
	exit 1
fi
Aut2exe //in "src/time-tracker.au3" //out "time-tracker.exe" //icon "src/Grafikartes-Flat-Retro-Modern-Time-machine.ico" //gui //x64

# Bug: Autoit compiler returns a bit early, even though compilation result *.exe file is not yet written to disk.
# Thus wait 5 seconds to be sure its written to disk
ping 127.0.0.1 -n 5 > nul
echo "Time-Tracker: Compilation done."


echo "Time-Tracker: Create Release Zip."
if ! which 7z ; then
    echo "Time-Tracker: 7z file archiver could not be found. Exiting."
	exit 1
fi
7z a time-tracker.zip time-tracker.exe
echo "Time-Tracker: Release Zip created."

echo "Time-Tracker: Build finished."