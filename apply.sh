#!/bin/sh
# This script was written by Frank Caviggia, Red Hat Consulting
# Last update was 16 September 2013
# This script is NOT SUPPORTED by Red Hat Global Support Services.
# Please contact Josh Waldman for more information.
#
# Script: apply.sh (stig-fix)
# Description: RHEL 6 Hardening Script (Master Script)
# License: GPL (see COPYING)
# Copyright: Red Hat Consulting, Sep 2013
# Author: Frank Caviggia <fcaviggi (at) redhat.com>

# ENVIRONMENT VARIABLES
DATE=`date +%F`
ARCH=`uname -i`
VERSION='1.0'
BASE_DIR=/opt/stig-fix
BACKUP=$BASE_DIR/backups
CONFIG=$BASE_DIR/config
LOG=/var/log/stig-fix-$DATE.log

# Script Version
function version() {
	echo "Hardening Scripts for RHEL 6 (v.$VERSION)"
}

# USAGE STATEMENT
function usage() {
cat << EOF
usage: $0 [options]

  -v    Show version
  -h 	Show this message
  -q	Quiet output for scripting use

Hardening Scripts for RHEL 6 (v.$VERSION)

Applies Hardening Configurations to a system.

The scripts apply best-practice configurations based upon 
the following standards:

     DISA RHEL 6 STIG

     NIST 800-53 SCAP (USGCB)

     NSA SNAC Guide for Red Hat Enterprise Linux

     Aqueduct Project
     https://fedorahosted.org/aqueduct

     Tresys Certifiable Linux Integration Platform (CLIP)
     http://oss.tresys.com/projects/clip
EOF
}

while getopts ":vhq" OPTION; do
	case $OPTION in
		v)
			version
			exit 0
			;;
		h)
			usage
			exit 0
			;;
		q)
			QUIET=1
			;;
		?)
			echo "ERROR: Invalid Option Provided!"
			echo
			usage
			exit 1
			;;
	esac
done

if [ -z "$QUIET" ]; then
	echo -e "\033[3m\033[1mRed Hat Enterprise 6 Linux Hardening Scripts\033[0m\033[0m"
	echo
	echo "These scripts will harden a system to specifications that" 
	echo "are based upon the the following standards:"
	echo
	cat << EOF
     DISA RHEL 6 STIG

     NIST 800-53 SCAP (USGCB)

     NSA SNAC Guide for Red Hat Enterprise Linux

     Aqueduct Project
     https://fedorahosted.org/aqueduct

     Tresys Certifiable Linux Integration Platform (CLIP)
     http://oss.tresys.com/projects/clip
EOF
	echo
fi

# Check for root user
if [[ $EUID -ne 0 ]]; then
	if [ -z "$QUIET" ]; then
		echo
		tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	fi
	exit 1
fi

if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mPlease snapshot or backup your system before running these scripts.\033[0m"
	echo
	echo -ne "\033[1mDo you want to continue?\033[0m [y/n]: "
	while read a; do
		case "$a" in
		y|Y)	break;;
		n|N)	exit 1;;
		*)	echo -n "[y/n]: ";;
		esac
	done
	echo
	echo -e "\033[1mStarting Configuration\033[0m"
fi

# CREATE LOG IF IT DOESN'T EXISIT
if [ ! -e $LOG ]; then
	touch $LOG
fi

echo "SCRIPT RUN: $(date)" >> $LOG
echo "Starting Configuration" >> $LOG

# BACKUP ORIGINAL SYSTEM CONFIGURATIONS
if [ -z "$QUIET" ]; then
	echo -n "Back up current configuration... " | tee -a $LOG
else
	echo -n "Back up current configuration... " >> $LOG
fi

if [ ! -d $BACKUP ]; then
	mkdir -p $BACKUP
fi

if [ ! -f "$BACKUP/sysctl.conf.orig" ]; then
	cp /etc/sysctl.conf $BACKUP/sysctl.conf.orig
fi

if [ ! -f "$BACKUP/login.defs.orig" ]; then
	cp /etc/login.defs $BACKUP/login.defs.orig
fi

if [ ! -f "$BACKUP/audit.rules.orig" ]; then
	cp /etc/audit/audit.rules $BACKUP/audit.rules.orig
fi

if [ ! -f "$BACKUP/auditd.conf.orig" ]; then
	cp /etc/audit/auditd.conf $BACKUP/auditd.conf.orig
fi

if [ ! -f "$BACKUP/limits.conf.orig" ]; then
	cp /etc/security/limits.conf $BACKUP/limits.conf.orig
fi

if [ ! -f "$BACKUP/sshd_config.orig" ]; then
	cp /etc/ssh/sshd_config $BACKUP/sshd_config.orig
fi

if [ ! -f "$BACKUP/ssh_config.orig" ]; then
	cp /etc/ssh/ssh_config $BACKUP/ssh_config.orig
fi

if [ ! -f "$BACKUP/system-auth.pam.orig" ]; then
	cp /etc/pam.d/system-auth $BACKUP/system-auth.pam.orig
fi

if [ ! -f "$BACKUP/ntp.conf.orig" ]; then
	cp /etc/ntp.conf $BACKUP/ntp.conf.orig
fi

if [ ! -f "$BACKUP/iptables.orig" ]; then
	cp /etc/sysconfig/iptables /etc/sysconfig/iptables.orig
	cp /etc/sysconfig/iptables $BACKUP/iptables.orig
fi

if [ ! -f "$BACKUP/ip6tables.orig" ]; then
	cp /etc/sysconfig/ip6tables /etc/sysconfig/ip6tables.orig
	cp /etc/sysconfig/ip6tables $BACKUP/ip6tables.orig
fi

if [ -z "$QUIET" ]; then
	echo "Done." | tee -a $LOG
else
	echo "Done." >> $LOG
fi

# APPLYING DEFAULT SYSTEM CONFIGURATIONS
if [ -z "$QUIET" ]; then
	echo -n "Applying base configuration files... " | tee -a $LOG
else
	echo -n "Applying base configuration files... " >> $LOG
fi

# CHANGE DIRECTORY TO BASE DIR
cd $BASE_DIR

#### START SSH FOR KEY GENERATION
`ls /etc/ssh/ssh_host_* | grep -q key`
if [ $? -ne 0 ]; then
	/etc/init.d/sshd restart &> /dev/null
fi

#### KERNEL PARAMETERS
cp ./config/sysctl.conf /etc/sysctl.conf
/sbin/sysctl -p /etc/sysctl.conf

#### USER AND PASSWORD CONFIGURATIONS
cp -f ./config/limits.conf /etc/security/limits.conf
cp -f ./config/login.defs /etc/login.defs

#### AUDITING RULES
cp -f ./config/auditd.conf /etc/audit/auditd.conf
if [ "$ARCH" == "x86_64" ]; then
	cp -f ./config/audit.rules /etc/audit/audit.rules
else
	grep -v 'b64' ./config/audit.rules > /etc/audit/audit.rules
fi

#### FIREWALL CONFIGURATIONS (IPV4/IPV6)
cp -f ./config/iptables /etc/sysconfig/iptables
cp -f ./config/ip6tables /etc/sysconfig/ip6tables

#### PAM CONFIGURATIONS
cp -f ./config/system-auth.pam /etc/pam.d/system-auth-local
ln -sf /etc/pam.d/system-auth-local /etc/pam.d/system-auth 

#### NTP CONFIGURATIONS
cp -f ./config/ntp.conf /etc/ntp.conf

if [ -z "$QUIET" ]; then
	echo "Done." | tee -a $LOG
else
	echo "Done." >> $LOG
fi

#### CLEAN TEMP FILES ON REBOOT WITH SCRUB (Server, Workstation)
rpm -q scrub &>/dev/null
if [ $? -eq 0 ]; then
	cp ./config/clean_system /etc/init.d/clean_system
	/sbin/chkconfig --add clean_system
	/sbin/chkconfig --level 06 clean_system on
	/sbin/chkconfig --level 12345 clean_system off
else
	if [ -z "$QUIET" ]; then
		echo
		echo "Scrub not installed. Secure /tmp and /var/tmp wipe service not installed." | tee -a $LOG
	else
		echo
		echo "Scrub not installed. Secure /tmp and /var/tmp wipe service not installed." >> $LOG
	fi
fi

# CAT I SECURITY ISSUES
if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mCAT I Security Issues\033[0m"
	echo
fi
echo >> $LOG
echo "CAT I Security Issues" >> $LOG
echo >> $LOG
for i in `ls cat1/*.sh`; do 
	if [ -z "$QUIET" ]; then
		echo  "#### Executing Script: $i" | tee -a $LOG
		sh $i 2>&1 | tee -a $LOG
	else
		echo "#### Executing Script: $i" >> $LOG
		sh $i >> $LOG
	fi
done;

# CAT II SECURITY ISSUES
if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mCAT II Security Issues\033[0m"
	echo
fi
echo >> $LOG
echo "CAT II Security Issues" >> $LOG
echo >> $LOG
for i in `ls cat2/*.sh`; do 
	if [ -z "$QUIET" ]; then
		echo  "#### Executing Script: $i" | tee -a $LOG
		sh $i 2>&1 | tee -a $LOG
	else
		echo "#### Executing Script: $i" >> $LOG
		sh $i >> $LOG
	fi
done;

# CAT III SECURITY ISSUES
if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mCAT III Security Issues\033[0m"
	echo
fi
echo >> $LOG
echo "CAT III Security Issues" >> $LOG
echo >> $LOG
for i in `ls cat3/*.sh`; do 
	if [ -z "$QUIET" ]; then
		echo  "#### Executing Script: $i" | tee -a $LOG
		sh $i 2>&1 | tee -a $LOG
	else
		echo "#### Executing Script: $i" >> $LOG
		sh $i >> $LOG
	fi
done;

# CAT IV SECURITY ISSUES
if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mCAT IV Security Issues\033[0m"
	echo
fi
echo >> $LOG
echo "CAT IV Security Issues" >> $LOG
echo >> $LOG
for i in `ls cat4/*.sh`; do 
	if [ -z "$QUIET" ]; then
		echo  "#### Executing Script: $i" | tee -a $LOG
		sh $i 2>&1 | tee -a $LOG
	else
		echo "#### Executing Script: $i" >> $LOG
		sh $i >> $LOG
	fi
done;

# CUSTOM HARDENING
if [ -z "$QUIET" ]; then
	echo
	echo -e "\033[1mAdditional Hardening\033[0m"
	echo
fi
echo >> $LOG
echo "Additional Hardening Scripts" >> $LOG
echo >> $LOG
for i in `ls misc/*.sh`; do
	if [ -z "$QUIET" ]; then
		echo  "#### Executing Script: $i" | tee -a $LOG
		sh $i 2>&1 | tee -a $LOG
	else
		echo "#### Executing Script: $i" >> $LOG
		sh $i >> $LOG
	fi
done;

if [ -z "$QUIET" ]; then
	echo 2>&1 | tee -a $LOG;
	tput setaf 2;echo -e "\033[1mConfiguration Complete!\033[0m";tput sgr0
fi
echo >> $LOG
echo "Configuration Complete!" >> $LOG

exit 0
