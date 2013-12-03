#!/bin/sh
#
# Script: toggle_usb (part of stig-fix)
# Description: RHEL 6 Hardening Script to enbale or disable a device
# License: GPL (see COPYING)
# Copyright: Red Hat Consulting, Sep 2013
# Author: Frank Caviggia <fcaviggi (at) redhat.com>

# GLOBAL VARIABLES
BASE_DIR=/opt/stig-fix
BASE_BACKUP=$BASE_DIR/backups

# USAGE STATEMENT
usage() {
cat << EOF
usage: $0 [options]

  -h 	Show this message

RHEL 6 Hardening Script

Toggles 'nousb' Kernel Argument on and off.

Included to resolve issues with usb keyboards and mice.
EOF
}

# APPLY SYSTEM CONFIGURATION
apply_configuration() {
	echo -n "Remove 'nousb' Kernel Arguement ... "
	/sbin/grubby --update-kernel=ALL --remove-args="nousb"
	/usr/bin/logger -p security.info "Disabled 'nousb' Kernel Argument (stig-fix)"
	echo "Done."

}
# RESTORE ORIGINAL CONFIGURATION
remove_configuration() {
	echo -n "Enable 'nousb' Kernel Arguement ... "
	/sbin/grubby --update-kernel=ALL --args="nousb"
	/usr/bin/logger -p security.info "Enabled 'nousb' Kernel Argument (stig-fix)"
	echo "Done."
}


# Check for root user
if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	fi
	exit 1
fi

while getopts ":h" OPTION; do
	case $OPTION in
		h)
			usage
			exit 0
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done


if [ -e $KERNEL_MODULE ]; then
	remove_configuration
else
	apply_configuration
fi

exit 0
