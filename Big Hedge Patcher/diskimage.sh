#!/bin/sh

#  diskimage.sh
#  Big Hedge
#
#  Created by Minh on 1/9/21.
#  Copyright © 2021 MinhTon. All rights reserved.


# Create a patched bootable disk image (ISO & DMG)

# - With the ISO format:

#        + You could restore the image
#        to a CD/DVD (well I guess no one use it anymore)
#        to create a bootable installer if your Mac has a
#        CD/DVD reader.

# - With the DMG format:

#        + You could restore the image
#        to a USB or internal volume using Disk Utility...

#        There's a better use for the DMG image. You could
#        restore the DMG image to an external volume or a USB
#        to create a bootable installer on Windows using TransMac
#        with the DMG file.

# For testing purposes, just un-comment this line
# set -e

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

echo 'Initializing scripts...' > /tmp/.automator_progress.txt

# Get the current directory of the script
CURRENT_DIR=$(dirname "$0")

echo "5" > /tmp/.automator_int.txt
# Extract the payload file
echo 'Extracting Patcher Files...' > /tmp/.automator_progress.txt

cp -rf "$CURRENT_DIR/payload" /tmp

echo "10" > /tmp/.automator_int.txt
unzip -o /tmp/payload -d /tmp
rm -rf /tmp/__MACOSX
echo "15" > /tmp/.automator_int.txt

# Set micropatcher location
Microlocation=$(echo "/tmp/big-sur-micropatcher-main")

# Get arguments
DISKIMAGE_MODE=$(cat /tmp/diskimage_mode.txt)
OUTPUT_PATH=$(cat /tmp/disk_image_path.txt)
INSTALL_APP=$(cat /tmp/automator_app.txt)

INSTALLER_PATH=$(basename "$INSTALL_APP")
INSTALLER_NAME=${INSTALLER_PATH%.*}

# Create temporary disk image
CREATE_TEMP_DISKIMAGE() {
    
    # Create an empty folder and use it as the source
    # folder for the hdiutil command
    # Will use this as the disk image mountpoint later.
    mkdir /tmp/automator
    
    # Unmount EVERY mounted volumes with the name
    # "Install macOS Big Sur" or
    # "Install macOS Big Sur Beta"
    # to prevent problems
    # this is a way better method than mine - asentienthedgehog
    echo 'Unmounting disks...' > /tmp/.automator_progress.txt
    
    echo "18" > /tmp/.automator_int.txt
    if [ -d /Volumes/Install\ macOS* ]; then
        diskutil unmount force /Volumes/Install\ macOS\ Big*
    fi
    
    if [ -d /Volumes/macOS\ Base* ]; then
        diskutil unmount force /Volumes/macOS\ Base*
    fi
    
    if [ -d /Volumes/SharedSupport ]; then
        diskutil unmount force /Volumes/SharedSupport
    fi
    
    echo "20" > /tmp/.automator_int.txt
    # Create a R/W disk image in the /tmp folder
    echo 'Creating Temporary Disk Image... This might take a couple of hours.' > /tmp/.automator_progress.txt
    
    hdiutil create /tmp/automator.dmg -volname "Automator" -size 14g -format UDRW -fs HFS+ -srcfolder /tmp/automator -verbose
    
    if [ ! -e /tmp/automator.dmg ]; then
        echo '[Error] Failed to create temporary disk image.' > /tmp/.automator_progress.txt
        exit_script
    fi
    
    echo "30" > /tmp/.automator_int.txt
    
    # Mount the created disk image to the mountpoint
    echo 'Mounting Temporary Disk Image....' > /tmp/.automator_progress.txt
    hdiutil attach /tmp/automator.dmg -nobrowse -noverify -mountpoint /tmp/automator
    echo "35" > /tmp/.automator_int.txt
    
    echo 'Creating Installer Disk Image... This might take a couple of hours.' > /tmp/.automator_progress.txt
    # Run createinstallmedia
    "$INSTALL_APP"/Contents/Resources/createinstallmedia --volume /tmp/automator --nointeraction
    echo "45" > /tmp/.automator_int.txt
    
    if [ ! -e /Volumes/"$INSTALLER_NAME"/"$INSTALLER_NAME.app" ]; then
        echo '[Error] Failed to create installer disk image.' > /tmp/.automator_progress.txt
        exit_script
    fi
    
    echo 'Patching Disk Image...' > /tmp/.automator_progress.txt
    # Run micropatcher
    "$Microlocation"/micropatcher.sh
    
    sudo "$Microlocation/install-setvars.sh"
    
    echo "55" > /tmp/.automator_int.txt
    
    if [ ! -e /Volumes/"$INSTALLER_NAME"/Patch-Version.txt ]; then
        echo '[Error] Failed to patch disk image.' > /tmp/.automator_progress.txt
        exit_script
    fi
    
    echo 'Preparing To Patch BaseSystem...' > /tmp/.automator_progress.txt
    # Detach/attach the disk image as a workaround for some weird problems...
    hdiutil detach -force /Volumes/Install\ macOS\ Big*
    hdiutil attach /tmp/automator.dmg -nobrowse -noverify
    echo "60" > /tmp/.automator_int.txt
    
    # Patch BaseSystem
    
    # Move BaseSystem to /tmp
    cp "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem.dmg" /tmp
    echo "65" > /tmp/.automator_int.txt
    
    echo 'Mounting BaseSystem...' > /tmp/.automator_progress.txt
    # Attach BaseSystem as a shadow disk image
    hdiutil attach -owners on /tmp/BaseSystem.dmg -nobrowse -noverify -shadow
    echo "70" > /tmp/.automator_int.txt
    
    echo 'Patching BaseSystem...' > /tmp/.automator_progress.txt
    # Copy post-install application
    cp -rf "$CURRENT_DIR/PostAutomator.app" /Volumes/macOS\ Base\ System/System/Applications/PostAutomator.app
    rm /Volumes/macOS\ Base\ System/System/Installation/CDIS/Recovery\ Springboard.app/Contents/Resources/Utilities.plist
    cp -rf "$CURRENT_DIR/Utilities.plist" /Volumes/macOS\ Base\ System/System/Installation/CDIS/Recovery\ Springboard.app/Contents/Resources/Utilities.plist
    cp -rf "$CURRENT_DIR/PostAutomator.app" /Volumes/macOS\ Base\ System/Applications/PostAutomator.app
    echo "75" > /tmp/.automator_int.txt
    
    echo 'Backing up BaseSystem...' > /tmp/.automator_progress.txt
    # Backup original BaseSystem
    mv "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem.dmg" "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem_stock.dmg"
    echo "80" > /tmp/.automator_int.txt
    
    echo 'Converting BaseSystem...' > /tmp/.automator_progress.txt
    # Convert shadow disk image to original format
    # hdiutil convert -format UDZO -o "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem.dmg" /tmp/BaseSystem.dmg -shadow
    hdiutil create "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem.dmg" -volname "macOS Base System" -format UDZO -srcfolder "/Volumes/macOS Base System" -verbose
    echo "85" > /tmp/.automator_int.txt
    
    # Copy patched boot.efi to prevent firmware's BaseSystem check
    cp -a $CURRENT_DIR/boot.efi "/Volumes/$INSTALLER_NAME/System/Library/CoreServices/boot.efi"

    # Add new boot icon
    rm -rf "/Volumes/$INSTALLER_NAME/.VolumeIcon.icns"
    cp -a "$CURRENT_DIR/Hedgehog_Boot.icns" "/Volumes/$INSTALLER_NAME/.VolumeIcon.icns"
    
    # Hiding unnecessary files...
    chflags hidden /Volumes/"$INSTALLER_NAME"/*.sh
    chflags hidden /Volumes/"$INSTALLER_NAME"/Patch-Version.txt
    chflags hidden /Volumes/"$INSTALLER_NAME"/bin
    chflags hidden /Volumes/"$INSTALLER_NAME"/kexts
    chflags hidden /Volumes/"$INSTALLER_NAME"/*.dylib

    # Adding support for non-APFS Macs... (HaxDoNotSealNoAPFSROMCheck)
    rm -rf /Volumes/"$INSTALLER_NAME"/HaxDoNotSeal.dylib
    rm -rf /Volumes/"$INSTALLER_NAME"/HaxSeal.dylib
    mv /Volumes/"$INSTALLER_NAME"/HaxDoNotSealNoAPFSROMCheck.dylib /Volumes/"$INSTALLER_NAME"/HaxDoNotSeal.dylib
    mv /Volumes/"$INSTALLER_NAME"/HaxSealNoAPFSROMCheck.dylib /Volumes/"$INSTALLER_NAME"/HaxSeal.dylib
    
    if [ ! -e "/Volumes/$INSTALLER_NAME/BaseSystem/BaseSystem_stock.dmg" ]; then
        echo '[Error] Failed to patch BaseSystem.' > /tmp/.automator_progress.txt
        exit_script
    fi
}


# Create ISO Image
CREATE_ISO() {
    
    # Remove the temporary 14GB+ disk image, to preserve space
    # for the conversion process below
    rm -rf /tmp/automator.dmg
    
    # Create a new ISO file that is optimized for restoring to CD/DVD (UDTO)
    hdiutil create "$OUTPUT_PATH" -volname "$INSTALLER_NAME" -format UDTO -fs HFS+ -srcfolder /Volumes/"$INSTALLER_NAME" -verbose
    
    # Remove the CDR extension, and now we have a Mac-compatible (Windows as well) ISO file.
    mv "$OUTPUT_PATH".cdr "$OUTPUT_PATH"
    
    # Force unmount the disk image before converting
    hdiutil detach -force /Volumes/"$INSTALLER_NAME"
}

# Create DMG Image
CREATE_DMG() {
    
    # Remove the temporary 14GB+ disk image, to preserve space
    # for the conversion process below
    rm -rf /tmp/automator.dmg
    
    echo 'Creating Disk Image... This might take a couple of hours.' > /tmp/.automator_progress.txt
    # Create a new compressed DMG file (UDZO)
    hdiutil create "$OUTPUT_PATH" -volname "$INSTALLER_NAME" -format UDZO -fs HFS+ -srcfolder /Volumes/"$INSTALLER_NAME" -verbose
    echo "95" > /tmp/.automator_int.txt
    
    if [ ! -e "$OUTPUT_PATH" ]; then
        echo '[Error] Failed create disk image.' > /tmp/.automator_progress.txt
        exit_script
    fi
    
    # Force unmount the disk image before converting
    hdiutil detach -force /Volumes/"$INSTALLER_NAME"
}

REMOVE_TEMP() {
    # Remove the big 14GB temporary disk image
    if [ -e /tmp/automator.dmg ]; then
        rm -rf /tmp/automator.dmg
    fi
    
    if [ -e /tmp/automator ]; then
        rm -rf /tmp/automator
    fi
    
    if [ -e /tmp/big-sur-micropatcher-main ]; then
        rm -rf /tmp/big-sur-micropatcher-main
    fi
    
    if [ -e /tmp/payload ]; then
        rm -rf /tmp/payload
    fi
    
    if [ -e /tmp/BaseSystem.dmg ]; then
        rm -rf /tmp/BaseSystem.dmg
    fi
}

# Call functions
if [ $DISKIMAGE_MODE == 1 ]; then
    CREATE_TEMP_DISKIMAGE
    CREATE_ISO
    REMOVE_TEMP
    exit_script
elif [ $DISKIMAGE_MODE == 2 ]; then
    CREATE_TEMP_DISKIMAGE
    CREATE_DMG
    REMOVE_TEMP
    echo 'Complete!' > /tmp/.automator_progress.txt
    echo "100" > /tmp/.automator_int.txt
    exit_script
fi

# thanks for helping with this, i never could have done anything near as good as this is! If I made something that worked, it wouldn't have been near as in-depth as this, or it would take me forever to do - asentienthedgehog
