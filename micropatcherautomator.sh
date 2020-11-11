#!/bin/zsh

echo 'This application is a GUI for the BarryKN Micropatcher.'
echo 'Thanks to MacHacJac, MinhTon, BenSova, iPixelGalaxy, BarryKN, ASentientBot, and others'

echo 'Detecting Micropatcher...'

if [ ! -d ~/Desktop/big-sur-micropatcher-main ]; then
    
    Output=$(sudo find ~/Desktop -type d -name '*big-sur-micropatcher-*')

    sudo mv $Output ~/Desktop/big-sur-micropatcher-main
fi

if [ -e /Volumes/Install\ macOS\ Big\ Sur\ Beta/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    echo Bootable macOS Big Sur USB detected! Patching...

    sh ~/Desktop/big-sur-micropatcher-main/micropatcher.sh

    echo 'Running install-setvars.sh'

    sleep 10

    osascript -e 'do shell script "~/Desktop/big-sur-micropatcher-main/install-setvars.sh" with administrator privileges'

    if [ -e /Volumes/Install\ macOS\ Big\ Sur\ Beta/kexts/IO80211Family-18G6032.kext.zip ]; then
        echo 'The patching process is now complete. You may now close this application and boot off of the USB.'
            
        exit
    fi
    
    if [ ! -e /Volumes/Install macOS\ Big\ Sur\Beta /kexts/IO80211Family-18G6032.kext.zip ]; then
        echo 'The patching process has failed! Please try again...'
            
        exit
    fi
fi

if [ ! -e /Applications/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    cd ~/Downloads/
    echo 'Downloading macOS 11.0.1 RC2 InstallAssistant.pkg (12GB). This will take a while! You can check the progression in Downloads'
    curl -o "InstallAssistant.pkg" http://swcdn.apple.com/content/downloads/35/61/001-77425-A_U0QWFSQBB6/3v38yvyhhg8zn9l7aj9nr4pqemhqhbvlq1/InstallAssistant.pkg
    sudo installer -pkg ~/Downloads/InstallAssistant.pkg -target /
fi

if [ -e /Applications/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    echo 'Install macoS Big Sur.app detected! Continuing...'

        if [ ! -e ~/Desktop/big-sur-micropatcher-main/micropatcher.sh ]; then
            echo 'Downloading Micropatcher, please wait...'
            cd ~/Desktop
            sudo curl -o "big-sur-micropatcher-main.zip" https://codeload.github.com/barrykn/big-sur-micropatcher/zip/v0.4.0
            echo 'Unzipping Micropatcher'
            unzip -q ~/Desktop/big-sur-micropatcher-main.zip
        fi
fi

#lttstore.com




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

osascript -e 'do shell script "/Applications/Install\\ macOS\\ Big\\ Sur\\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/USB --nointeraction" with administrator privileges'

if [ -e /Volumes/USB ]; then
    echo createinstallmedia failed! Please try again...
    exit
fi

if [ ! -e  /Volumes/Install macOS Big Sur/Install\ macOS\ Big\ Sur\ Beta.app ]; then
    echo createinstallmedia failed! Please try again...
    exit
fi

echo 'Finished running createinstallmedia.  Thanks to iPixelGalaxy for the Install macOS Big Sur.app check'

if [ ! -d ~/Desktop/big-sur-micropatcher-main ]; then
    echo 'Please re-download Micropatcher, then try again.'
    exit
fi

sh ~/Desktop/big-sur-micropatcher-main/micropatcher.sh

echo 'Running install-setvars.sh'

sleep 10

osascript -e 'do shell script "~/Desktop/big-sur-micropatcher-main/install-setvars.sh" with administrator privileges'

if [ -e '/Volumes/Install macOS Big Sur/kexts/IO80211Family-18G6032.kext.zip' ]; then
    echo 'The patching process is now complete. You may now close this application and boot off of the USB.'
    exit
fi

if [ ! -e '/Volumes/Install macOS Big Sur Beta/kexts/IO80211Family-18G6032.kext.zip' ]; then
    echo 'The patching process has failed! Please try again...'
    exit
fi
