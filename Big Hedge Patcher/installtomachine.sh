#!/bin/sh

#  installtomachine.sh
#  Big Hedge
#
#  Created by Minh on 1/31/21.
#  Copyright © 2021 MinhTon. All rights reserved.

# For testing purposes, just un-comment this line
# set -e

# Get the current directory of the script and the password
CURRENT_DIR=$(dirname "$0")
PASSWORD="$1"

sleep 3

# Inject ASentientBot's Hax
launchctl setenv DYLD_INSERT_LIBRARIES "$CURRENT_DIR/BestHax.dylib"
echo "$PASSWORD" | sudo -S launchctl setenv DYLD_INSERT_LIBRARIES "$CURRENT_DIR/BestHax.dylib"

sleep 3

# Setting NVRAM & disable AMFI
# echo "$PASSWORD" | sudo -S nvram -c
echo "$PASSWORD" | sudo -S nvram boot-args="-no_compat_check amfi_get_out_of_my_way=1"
# echo "$PASSWORD" | sudo -S nvram manufacturing-enter-picker=true # For testing purposes


