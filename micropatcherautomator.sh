#!/bin/zsh
echo 'This application is a GUI for the BarryKN Micropatcher.'
echo 'Thanks to MacHacJac, BenSova, iPixelGalaxy, BarryKN, ASentientBot, and others'

if [ -e /Volumes/Install\ macOS\ Big\ Sur\ Beta/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    echo Bootable macOS Big Sur USB detected! Patching...

    sh ~/Desktop/big-sur-micropatcher-main/micropatcher.sh

    echo 'Running install-setvars.sh'

    sleep 10

    sudo ~/Desktop/big-sur-micropatcher-main/install-setvars.sh

    if [ -e /Volumes/Install\ macOS\ Big\ Sur\ Beta.app/AirPortAtheros40-17G14033+pciid.kext.zip ]; then
            echo 'The patching process is now complete. You may now close this application and boot off of the USB.'
            exit
    fi
    
    if [ ! -e /Volumes/Install\ macOS\ Big\ Sur\ Beta.app/AirPortAtheros40-17G14033+pciid.kext.zip ]; then
            echo 'The patching process has failed! Please try again...'
            exit
    fi
fi

if [ ! -e /Applications/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    cd ~/Downloads/
    echo 'Downloading macOS 11.0.1 B1 InstallAssistant.pkg (12GB). This will take a while! You can check the progression in Downloads'
    curl -o "InstallAssistant.pkg" http://swcdn.apple.com/content/downloads/21/61/001-58883-A_349P9V4VSE/vgf6b2ccrg6y0mk0y526c8hw8knbdwko2v/InstallAssistant.pkg
    sudo installer -pkg ~/Downloads/InstallAssistant.pkg -target /
fi

if [ -e /Applications/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    echo 'Install macoS Big Sur Beta.app detected! Continuing...'

        if [ ! -e ~/Desktop/big-sur-micropatcher-main/micropatcher.sh ]; then
            echo 'Downloading Micropatcher, please wait...'
            cd ~/Desktop
            sudo curl -o "big-sur-micropatcher-main.zip" https://codeload.github.com/barrykn/big-sur-micropatcher/zip/v0.4.0
            echo 'Unzipping Micropatcher'
            unzip -q ~/Desktop/big-sur-micropatcher-main.zip
        fi
fi

#lttstore.com

echo 'Detecting Micropatcher...'

if [ ! -d ~/Desktop/big-sur-micropatcher-main ]; then
    
    Output=$(sudo find ~/Desktop -type d -name '*big-sur-micropatcher-*')

    sudo mv $Output ~/Desktop/big-sur-micropatcher-main
fi


if [ ! -e ~/Desktop/big-sur-micropatcher-main/micropatcher.sh ]; then
    echo 'Downloading Micropatcher, please wait...'
    cd ~/Desktop
    sudo curl -o "big-sur-micropatcher-main.zip" https://codeload.github.com/barrykn/big-sur-micropatcher/zip/v0.4.0
    echo 'Unzipping Micropatcher'
    unzip -q ~/Desktop/big-sur-micropatcher-main.zip
    DownloadedOutput=$(sudo find ~/Desktop -type d -name '*big-sur-micropatcher-*')

    sudo mv $DownloadedOutput ~/Desktop/big-sur-micropatcher-main
    mv ~/Desktop/big-sur-micropatcher-0.4.0 ~/Desktop/big-sur-micropatcher-main
fi

if [ ! -e ~/Desktop/big-sur-micropatcher-main/micropatcher.sh ]; then
    echo 'Micropatcher not detected. Please make sure that Micropatcher is named big-sur-micropatcher-main'
    exit
fi

echo 'Micropatcher detected! Continuing...'

if [ ! -d /Volumes/USB ]; then
    echo '/Volumes/USB is not mounted, please confirm that your USB is detected by the machine and named "USB"'
    exit
fi

echo 'Running createinstallmedia. DO NOT CLOSE.'
echo 'To check to see if createinstallmedia is progressing, open Activity Monitor and search createinstallmedia.'

sudo /Applications/Install\ macOS\ Big\ Sur\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/USB --nointeraction

if [ ! -e  /Volumes/Install macOS Big Sur Beta/Install macOS Big Sur Beta.app ]; then
    echo createinstallmedia failed! Please try again...
    exit
fi

echo 'Finished running createinstallmedia.  Thanks to iPixelGalaxy for the Install macOS Big Sur Beta.app check'

if [ ! -d ~/Desktop/big-sur-micropatcher-main ]; then
    echo 'Please re-download Micropatcher, then try again.'
    exit
fi

sh ~/Desktop/big-sur-micropatcher-main/micropatcher.sh

echo 'Running install-setvars.sh'

sleep 10

sudo ~/Desktop/big-sur-micropatcher-main/install-setvars.sh

if [ -e /Volumes/Install\ macOS\ Big\ Sur\ Beta.app/AirPortAtheros40-17G14033+pciid.kext.zip ]; then
    echo 'The patching process is now complete. You may now close this application and boot off of the USB.'
    exit
fi

if [ ! -e /Volumes/Install\ macOS\ Big\ Sur\ Beta.app/AirPortAtheros40-17G14033+pciid.kext.zip ]; then
    echo 'The patching process has failed! Please try again...'
    exit
fi
