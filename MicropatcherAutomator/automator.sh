#!/bin/sh

exit_script() {
    rm -rf /tmp/automator_progress.txt
    rm -rf /tmp/automator_int.txt
    exit
}

if [ -e /tmp/automator_int.txt ]; then
    rm /tmp/automator_int.txt
fi
if [ -e /tmp/automator_progress.txt ]; then
    rm /tmp/automator_progress.txt
fi

echo 'This application is a GUI for the BarryKN Micropatcher.'
echo 'Thanks to MinhTon, MacHacJac, BenSova, Jackluke, iPixelGalaxy, BarryKN, ASentientBot, and others'

DIR=$(dirname "$0")
#Volume Name
USB_VOLUME=$(cat /tmp/automator_volume.txt)
echo $USB_VOLUME Chosen!
echo "5" > /tmp/automator_int.txt
sleep 3
Microlocation=$( echo "$DIR/big-sur-micropatcher-main" )
echo "10" > /tmp/automator_int.txt
colonins=$(cat /tmp/automator_app.txt)
installer=$(echo "$colonins" | tr : / | cut -c 7- | sed 's/.$//')
installdir=${installer%.*}
installnodir=$( echo "$installdir" | perl -p -e 's/^.*?Install/Install/' )
installapp=$( echo $installnodir.app )

#lttstore.com

echo 'Creating Bootable Installer. DO NOT CLOSE.'
echo 'Creating Bootable Installer (See Verbose Output for Progress)...' > /tmp/automator_progress.txt
echo "20" > /tmp/automator_int.txt

"/Applications/$installapp/Contents/Resources/createinstallmedia" --volume /Volumes/"$USB_VOLUME" --nointeraction

    DISK_IDENTIFIER=$(df /Volumes/"$installnodir" | tail -1 | sed -e 's@ .*@@' | sed 's/.\{2\}$//')
    diskutil unmount force "$DISK_IDENTIFIER"
    echo "25" > /tmp/automator_int.txt
    diskutil mount "$DISK_IDENTIFIER"
    echo "30" > /tmp/automator_int.txt

################################
if [ ! -e  /Volumes/"$installnodir"/"$installnodir.app" ]; then
    echo 'createinstallmedia failed! Please try again...'
    echo '[Error] createinstallmedia failed! Please try again...' > /tmp/automator_progress.txt
    exit_script
fi

echo 'Finished Creating Bootable Installer.  Thanks to iPixelGalaxy for the Install macOS Big Sur.app check'
echo 'Finished Creating Bootable Installer.' > /tmp/automator_progress.txt
echo "40" > /tmp/automator_int.txt

sh "$Microlocation/micropatcher.sh"

echo 'Running install-setvars.sh'
echo 'Setting Boot Arguments...' > /tmp/automator_progress.txt
echo "50" > /tmp/automator_int.txt

sudo "$Microlocation/install-setvars.sh"

echo "Patching Installer BaseSystem..."
echo 'Patching Installer BaseSystem...' > /tmp/automator_progress.txt
echo "55" > /tmp/automator_int.txt
    cd "/Volumes/$installnodir/BaseSystem"
    diskutil list | grep "(disk image):" | sed 's/.\{14\}$//' | xargs -L1 diskutil eject
    if [ -e BaseSystem.dmg.shadow ]; then
        rm Basesystem.dmg.shadow
    fi
    hdiutil attach -owners on "/Volumes/$installnodir/BaseSystem/BaseSystem.dmg" -nobrowse -shadow
    cd "/Volumes/macOS Base System/System/Applications"
    echo "60" > /tmp/automator_int.txt
    cp -a "$DIR/PostAutomator.app" PostAutomator.app
    cd "/Volumes/macOS Base System/System/Installation/CDIS/Recovery Springboard.app/Contents/Resources"
    echo "65" > /tmp/automator_int.txt
    rm Utilities.plist
    echo "68" > /tmp/automator_int.txt
    cp -a "$DIR/Utilities.plist" Utilities.plist
    cd "/Volumes/macOS Base System/Applications"
    echo "70" > /tmp/automator_int.txt
    cp -a "$DIR/PostAutomator.app" PostAutomator.app
    echo "73" > /tmp/automator_int.txt
    hdiutil detach "/Volumes/macOS Base System"
    cd "/Volumes/$installnodir/BaseSystem"
    echo "75" > /tmp/automator_int.txt

    DISK_IDENTIFIER=$(df /Volumes/"$installnodir" | tail -1 | sed -e 's@ .*@@')
    diskutil unmount force "$DISK_IDENTIFIER"
    echo "78" > /tmp/automator_int.txt
    diskutil mount "$DISK_IDENTIFIER"
    echo "80" > /tmp/automator_int.txt

    hdiutil convert -format UDZO -o "/Volumes/$installnodir/BaseSystem/BaseSystem2.dmg" "/Volumes/$installnodir/BaseSystem/BaseSystem.dmg" -shadow
    echo "85" > /tmp/automator_int.txt
    cd "/Volumes/$installnodir/BaseSystem"
    mv BaseSystem.dmg BaseSystembackup.dmg
    mv BaseSystem2.dmg BaseSystem.dmg
    echo "90" > /tmp/automator_int.txt
    cp -a $DIR/boot.efi "/Volumes/$installnodir/System/Library/CoreServices/boot.efi"
    echo "95" > /tmp/automator_int.txt

rm -rf "/Volumes/$installnodir/.VolumeIcon.icns"
cp -a "$DIR/Hedgehog_Boot.icns" "/Volumes/$installnodir/.VolumeIcon.icns"
echo "100" > /tmp/automator_int.txt

#AutoRestart
if [ -e /Volumes/"$installnodir"/kexts/IO80211Family-18G6032.kext.zip ]; then
    echo 'The patching process is now complete!'
    echo 'Complete!' > /tmp/automator_progress.txt
    exit_script
fi

if [ ! -e "/Volumes/$installnodir/kexts/IO80211Family-18G6032.kext.zip" ]; then
    echo 'The patching process has failed! Please try again...'
    echo '[Error] The patching process has failed! Please try again...' > /tmp/automator_progress.txt
    exit_script
fi

exit_script

