#!/bin/sh

#  postautomator.sh
#
#
#  Created by Nathan Taylor on 11/26/20.
#Drives
VOLUME=$1
echo $VOLUME
MODEL=$(sysctl -n hw.model)
#Model,OSVER
OSVER=$(defaults read /Volumes/"$VOLUME"/System/Library/CoreServices/SystemVersion ProductVersion)
Model=$(sysctl hw.model)
ModelIdentifier=$(echo $Model)
ReadModel=$(sysctl -n hw.model)
echo $ReadModelr running $OSVER detected!
INSTALLER=$(dirname "$0")
if [ -d "/Volumes/Image Volume" ]; then
    echo '[Out] Recovery mode detected!'
    INSTALLER=/Volumes/Image\ Volume
fi
echo "$INSTALLER"

#
#thank you Ben for introducing me to this!
case $MODEL in
        MacBook[4-7],?|Macmini[34],1|MacBookAir[23],[12]|MacBookPro[457],[0-9]|iMac[0-9],[0-9]|iMac10,1)
        NoAccel2010="yes"
esac

case $MODEL in
        MacPro3,[1-3])
        MacPro31="yes"
        
esac

case $MODEL in
        Macmini5,[12]|MacBookAir4,[12]|MacBookPro8,[0-9]|iMac12,[12])
        NoAccel2011="yes"
esac

case $MODEL in
        iMac11,[1-3])
        NoAccel2011Imac="yes"
esac

case $MODEL in
        Macmini6,[12]|MacBookAir5,[12]|MacBookPro9,[12]|MacBookPro10,[12]|iMac13,[12])
        Accel2012="yes"
    
esac

case $MODEL in
        MacPro[45],1)
        Accel2012="yes"
esac

#the actual patching process

if [[ $MacPro31 = yes ]]; then
    echo "[Out] If you have the stock GPU, please downgrade to an older OS."
    echo "Assuming you have a Metal compatible GPU, you will have acceleration. If you have the original GPU, your really should upgrade."
    sleep 5
    "$INSTALLER/patch-kexts.sh"  --2010 "/Volumes/$VOLUME"
    echo "[Out] Finished Patching! You may now restart..."
    exit
fi

if [[ $MacPro == yes ]]; then
    echo "[Out] If you have the stock GPU, please downgrade to an older OS."
    echo "Assuming you have a Metal compatible GPU, you will have acceleration. If you have the original GPU, your really should upgrade."
    sleep 5
    "$INSTALLER/patch-kexts.sh"  --2012 "/Volumes/$VOLUME"
    echo "[Out] Finished Patching! You may now restart..."    exit
fi

if [[ $NoAccel2010 == yes ]]; then
    echo "[Out] You will not have acceleration, please check verbose output for more info."
    echo "This machine will not have graphics acceleration, and will therefore be nearly unusable."
    echo "Please cancel this patcher and downgrade to Catalina or older. This  will continue in 30 seconds if you do not cancel."
    
    sleep 30

    "$INSTALLER/patch-kexts.sh"  --2010 "/Volumes/$VOLUME"
    echo "[Out] Finished Patching! You may now restart..."
    exit
fi


if [[ $NoAccel2011 == yes ]]; then
    echo "[Out] You will not have acceleration, please check verbose output for more info."
    echo "This machine will not have graphics acceleration, and will therefore be nearly unusable."
    echo "Please cancel this patcher and downgrade to Catalina or older. This  will continue in 30 seconds if you do not cancel."
        
        sleep 30

        "$INSTALLER/patch-kexts.sh" --2011 "/Volumes/$VOLUME"

    echo "[Out] Finished Patching! You may now restart..."
    exit
fi

if [[ $NoAccel2011Imac == yes ]]; then
    echo "[Out] You will not have acceleration, please check verbose output for more info."
    echo "This machine will not have graphics acceleration, and will therefore be nearly unusable."
    echo "Please cancel this patcher and downgrade to Catalina or older. This  will continue in 30 seconds if you do not cancel."
        
        sleep 30

        "$INSTALLER"/patch-kexts.sh  --IMAC11 "/Volumes/$VOLUME"
    echo "[Out] Finished Patching! You may now restart..."
    exit
fi

if [[ $Accel2012 = yes ]]; then
    echo "[Out] Patchable Mac Detected!"
    "$INSTALLER/patch-kexts.sh" --2012 "/Volumes/$VOLUME"
    echo "[Out] Finished Patching! You may now restart..."
    exit
fi

echo "If you can read this, that means that I probably broke something and the patching process has failed because your Mac model could not be determined. Please report this issue on GitHub along with your model of Mac. Sorry for the inconvenience!"

echo "[Error] Error! Check verbose output for more info"

exit


