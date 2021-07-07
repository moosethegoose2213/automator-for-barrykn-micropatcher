#!/bin/sh
#
# Created by Nathan Taylor (ASentientHedgehog)
#
# Slightly modified by MinhTon
#

exit_script() {

    # Remove all patcher traces :)
    rm -rf /tmp/.automator_progress.txt
    rm -rf /tmp/.automator_int.txt
    rm -rf /tmp/automator_app.txt
    rm -rf /tmp/automator_volume.txt
    rm -rf /tmp/payload
    rm -rf /tmp/big-sur-micropatcher-main
    
    # And exit!
    exit
}

# Well again, check for traces and delete all of them
# to prevent some weird glitches on the GUI

if [ -e /tmp/.automator_int.txt ]; then
    rm /tmp/.automator_int.txt
fi
if [ -e /tmp/.automator_progress.txt ]; then
    rm /tmp/.automator_progress.txt
fi
if [ -e /tmp/payload ]; then
    rm /tmp/payload
fi
if [ -e /tmp/big-sur-micropatcher-main ]; then
    rm /tmp/big-sur-micropatcher-main
fi

echo "Initializing script..."

DIR=$(dirname "$0")

# Get the selected volume name from the GUI
USB_VOLUME=$(cat /tmp/automator_volume.txt)

# This is how I (Minh) let this shell script to control
# the GUI :) :
#   /tmp/.automator_int.txt: The value for the progress bar
#   /tmp/.automator_progress.txt: The output text to display above the progress bar

echo "5" > /tmp/.automator_int.txt
sleep 3
echo "8" > /tmp/.automator_int.txt

# Move the payload file containing BarryKN's micropatcher
# to /tmp and decompress it
cp -rf "$DIR/payload" /tmp
echo "10" > /tmp/.automator_int.txt
unzip -o /tmp/payload -d /tmp
rm -rf /tmp/__MACOSX
Microlocation=$(echo "/tmp/big-sur-micropatcher-main")

echo "20" > /tmp/.automator_int.txt
colonins=$(cat /tmp/automator_app.txt)
installer=$(echo "$colonins" | tr : / | cut -c 7- | sed 's/.$//')
installdir=${installer%.*}
installnodir=$( echo "$installdir" | perl -p -e 's/^.*?Install/Install/')
installapp=$(echo $installnodir.app)

echo 'Creating Bootable Installer... This might take a couple of hours.' > /tmp/.automator_progress.txt

# Force unmount / remount volume before running createinstallmedia
DISK_IDENTIFIER=$(df /Volumes/"$USB_VOLUME" | tail -1 | sed -e 's@ .*@@')
diskutil unmount force "$DISK_IDENTIFIER"

# Unmount EVERY mounted volumes with the name
# "Install macOS Big Sur" or
# "Install macOS Big Sur Beta"
# to prevent problems
if [ -d /Volumes/Install\ macOS* ]; then
    diskutil unmount force /Volumes/Install\ macOS\ Big*
fi

if [ -d /Volumes/macOS\ Base* ]; then
    diskutil unmount force /Volumes/macOS\ Base*
fi

if [ -d /Volumes/SharedSupport ]; then
    diskutil unmount force /Volumes/SharedSupport
fi

# Remount volume
diskutil mount "$DISK_IDENTIFIER"
echo "25" > /tmp/.automator_int.txt

# Run createinstallmedia to create an unpatched bootable installer

if ! "$colonins"/Contents/Resources/createinstallmedia --volume /Volumes/"$USB_VOLUME" --nointeraction ; then
    echo '[Error] createinstallmedia failed! Please try again...' > /tmp/.automator_progress.txt
    exit_script
fi

echo "30" > /tmp/.automator_int.txt

# Force unmount & remount the volume... to prepare for patching BaseSystem
DISK_IDENTIFIER=$(df /Volumes/"$installnodir" | tail -1 | sed -e 's@ .*@@' | sed 's/.\{2\}$//')
diskutil unmount force "$DISK_IDENTIFIER"
diskutil mount "$DISK_IDENTIFIER"
echo "35" > /tmp/.automator_int.txt

# ASentientHedgehog's weird way of checking if createinstallmedia works...
# Weird, but it works anyways
if [ ! -e  /Volumes/"$installnodir"/"$installnodir.app" ]; then
    echo '[Error] createinstallmedia failed! Please try again...' > /tmp/.automator_progress.txt
    exit_script
fi

echo "40" > /tmp/.automator_int.txt

# Patch the bootable installer with BarryKN's micropatcher
sh "$Microlocation/micropatcher.sh"

# Run install-setvars
echo 'Setting Boot Arguments...' > /tmp/.automator_progress.txt
echo "50" > /tmp/.automator_int.txt

sudo "$Microlocation/install-setvars.sh"

# Most important part (and unique part) of this patcher
# Patching BaseSystem!!!
echo 'Patching Installer BaseSystem...' > /tmp/.automator_progress.txt
echo "55" > /tmp/.automator_int.txt

# If the user runs the patcher multiple times, the Preboot volume of BaseSystem
# just randomly mounts itself... (we don't know what caused this as of now)
# So... ASentientHedgehog's weird fix again: Unmount all of the disk images
diskutil list | grep "(disk image):" | sed 's/.\{14\}$//' | xargs -L1 diskutil eject

# Mount BaseSystem as a shadow disk image with R/W permission
hdiutil attach -owners on "/Volumes/$installnodir/BaseSystem/BaseSystem.dmg" -nobrowse -shadow

# Copying our Post-install app to BaseSystem /Applications folder
echo "65" > /tmp/.automator_int.txt
cp -a "$DIR/PostAutomator.app" /Volumes/macOS\ Base\ System/System/Applications/PostAutomator.app

# Modify Utilities.plist to add the app to the Utilities list in Recovery
echo "68" > /tmp/.automator_int.txt
rm /Volumes/macOS\ Base\ System/System/Installation/CDIS/Recovery\ Springboard.app/Contents/Resources/Utilities.plist
echo "70" > /tmp/.automator_int.txt
cp -a "$DIR/Utilities.plist" /Volumes/macOS\ Base\ System/System/Installation/CDIS/Recovery\ Springboard.app/Contents/Resources/Utilities.plist
echo "73" > /tmp/.automator_int.txt

# Unmount the shadow disk image
hdiutil detach "/Volumes/macOS Base System"
echo "75" > /tmp/.automator_int.txt

# Force unmount/remount the volume before converting the
# modified BaseSystem to its original state
DISK_IDENTIFIER=$(df /Volumes/"$installnodir" | tail -1 | sed -e 's@ .*@@')
diskutil unmount force "$DISK_IDENTIFIER"
echo "78" > /tmp/.automator_int.txt
diskutil mount "$DISK_IDENTIFIER"
echo "80" > /tmp/.automator_int.txt

# Convert the modified BaseSystem to the original read-only format
hdiutil convert -format UDZO -o "/Volumes/$installnodir/BaseSystem/BaseSystem2.dmg" "/Volumes/$installnodir/BaseSystem/BaseSystem.dmg" -shadow
echo "90" > /tmp/.automator_int.txt

# Hmm... should we back up the original BaseSystem image?
# Well, just backing it up for testing purposes!
mv /Volumes/"$installnodir"/BaseSystem/BaseSystem.dmg /Volumes/"$installnodir"/BaseSystem/BaseSystembackup.dmg
mv /Volumes/"$installnodir"/BaseSystem/BaseSystem2.dmg /Volumes/"$installnodir"/BaseSystem/BaseSystem.dmg
echo "93" > /tmp/.automator_int.txt

# Copying ASentientBot's patched boot.efi to bypass the
# firmware's BaseSystem validation check
cp -a "$DIR/boot.efi" "/Volumes/$installnodir/System/Library/CoreServices/boot.efi"
echo "95" > /tmp/.automator_int.txt

# Remove the original Boot Picker icon
rm -rf "/Volumes/$installnodir/.VolumeIcon.icns"
# And add the new gorgeous hedgehog Boot Picker icon!
cp -a "$DIR/Hedgehog_Boot.icns" "/Volumes/$installnodir/.VolumeIcon.icns"
echo "100" > /tmp/.automator_int.txt

# Hiding unnecessary files...
chflags hidden /Volumes/"$installnodir"/*.sh
chflags hidden /Volumes/"$installnodir"/Patch-Version.txt
chflags hidden /Volumes/"$installnodir"/bin
chflags hidden /Volumes/"$installnodir"/kexts
chflags hidden /Volumes/"$installnodir"/*.dylib

# Adding support for non-APFS Macs... (HaxDoNotSealNoAPFSROMCheck)
rm -rf /Volumes/"$installnodir"/HaxDoNotSeal.dylib
rm -rf /Volumes/"$installnodir"/HaxSeal.dylib
mv /Volumes/"$installnodir"/HaxDoNotSealNoAPFSROMCheck.dylib /Volumes/"$installnodir"/HaxDoNotSeal.dylib
mv /Volumes/"$installnodir"/HaxSealNoAPFSROMCheck.dylib /Volumes/"$installnodir"/HaxSeal.dylib

# ASentientHedgehog's weird way of checking if
# the patching process completes...
# "It just works!" - Apple
if [ -e /Volumes/"$installnodir"/Patch-Version.txt ]; then
    echo 'Complete!' > /tmp/.automator_progress.txt
    exit_script
fi

if [ ! -e "/Volumes/$installnodir/Patch-Version.txt" ]; then
    echo '[Error] The patching process has failed!' > /tmp/.automator_progress.txt
    exit_script
fi

exit_script
