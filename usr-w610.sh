#!/bin/bash
# script to find usr-w610 serial to network converters on a local network
# using ubuntu 24.04.2 | linux
# Joseph Breiting 2025

# This script is the linux equivalent to USR-VCOM's Search USR232-WIFI-X function
# as well a virtual port setup tool

# Needs 'arping', 'arp-scan', and 'nmap' utilities
# "sudo apt install iputils-arping arp-scan nmap" on ubuntu

# support for multiple devices on network
# todo: copy minus 1 nomenclature for displaying mac to user
# todo: append last 2 bytes of mac minus 1 to virtual serial port location ie. /dev/vcom8A10

# windows software available at www.pusr.com
# usr-vcom = virtual serial port software

# WEIRDNESS: the vcom software reports the mac address as the mac minus 1, 
# windows arp and ubuntu arp-scan report the mac as the actual mac
# but the labeling on the device shows the mac minus 1. So rather than xxx79 it is xxx78.
# I also noticed that it has the modified mac hardcoded as a BSSID for the wireless AP,
# so mabye they are using it as a way to find the device by BSSID when you reset it to
# factory defaults and are not actually connected to a network.

# !! This script will output the psuedo mac as the devices label as well as the virtual port suffix to match
# !! the labeling on the device.

# usr-w610 device setup step
#  --Load default settings
#  --Change from AP to STA, and connect to my home network
#  --Reboot usr-w610

# check if root if so there is no need for "sudo" command but if not check to make sure it is available
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	if ! command -v sudo &> /dev/null; then echo "missing sudo, only an admin can run scans."; exit 1; fi
	SUDO="sudo"
fi

# check for required programs
if ! command -v arping &> /dev/null; then echo "missing arping"; exit 1; fi
if ! command -v arp-scan &> /dev/null; then echo "missing arp-scan"; exit 1; fi
if ! command -v nmap &> /dev/null; then echo "missing nmap"; exit 1; fi

# find interface connected to the web
network=$(ip r | grep "default" | awk -F'dev ' '{print $2}' | awk '{print $1}')

# find devices
defaultip=10.10.100.254
replies=$($SUDO arping -w2 -I $network $defaultip | grep "reply" | awk -F']' '{print $1}' | awk -F'[' '{print $2}' | sort -u)

# exit if none found
if [ -z "$replies" ] ; then echo "none found :("; exit 1; fi

# find ip for each mac address
grepexpr=$(echo $replies | sed 's/ /\\|/g')
devices=$($SUDO arp-scan -ql | grep -i $grepexpr | sed 's/\t/-/g')

for dev in $devices
do
  # split mac and ip
  mac=${dev#*-}
  ip=${dev%-*}
  
  # psuedo mac and label
  macstr=$(echo $mac | sed 's/://g')
  machex="0x$macstr"
  bssiddec=$((machex-1))
  bssidstr=$(printf "%x\n" $bssiddec)
  macsuffix="${bssidstr: -4}"
  separator=":"
  bssidlow=$(echo "$bssidstr" | sed "s/../&${separator}/g" | sed 's/'"$separator"'$//')
  
  bssid=$(echo "${bssidlow^^}")
  macid="${macsuffix^^}"
  
  # find port on a given ip that has the "ospf-lite" service and is open
  port=$($SUDO nmap -sS --open $ip | grep "ospf-lite" | awk -F'/' '{print $1}')
  
  # macid and ip:port
  echo -e "$bssid\\t$ip:$port"
  
  # socat command for virtual serial port connection
  echo "socat pty,link=$HOME/vcom$macid,waitslave,group-late=dialout,mode=660 tcp:$ip:$port &"
done

# you shall not pass
exit 0

# add connect to arg [script AABB] to run socat if AABB match a single results macid
