#!/bin/bash

#make sure tools work as expected
LANG=C

#this specifies which Headline level is used
HL='===='

CPU=`cat /proc/cpuinfo  | grep 'model name' | awk -F\: '{print $2}'|uniq|sed -e 's/ //'`
MHz=`cat /proc/cpuinfo | grep 'cpu MHz' | awk -F\: '{print $2}'|uniq|sed -e 's/ //'`
CPUCOUNT=`cat /proc/cpuinfo|grep "physical id"|uniq|wc -l`
RAM=`cat /proc/meminfo | grep MemTotal | awk -F\: '{print $2}' | awk -F\  '{print $1 " " $2}'`
SWAP=`cat /proc/meminfo | grep SwapTotal | awk -F\: '{print $2}' | awk -F\  '{print $1 " " $2}'`
SYSTEM=`uname -sr`
HOSTNAME=`(hostname -f || hostname) 2>/dev/null`

# look for known Distributions
if [ -e /etc/debian_version ]; then
  OS="Debian `cat /etc/debian_version`"
elif [ -e /etc/redhat-release ]; then
  OS=`cat /etc/redhat-release`
elif [ -e /etc/SuSE-release ]; then
  OS=`cat /etc/SuSE-release |head -n1`
elif [ -e /etc/gentoo-release ]; then
  OS=`< /etc/gentoo-release`
else
  OS='unknown'
fi

echo "
$HL General $HL

^ Hostname | $HOSTNAME |
^ CPU      | $CPU      |
^ MHz      | $MHz      |
^ # CPU    | $CPUCOUNT |
^ RAM      | $RAM      |
^ Swap     | $SWAP     |
^ System   | $SYSTEM   |
^ OS       | $OS       |
"

echo -e "$HL Network $HL\n"
for DEV in `/sbin/ifconfig -a |grep '^\w'|awk '!/lo/{print $1}'`
do
  IP=`/sbin/ifconfig $DEV |awk -F\: '/inet / {print $2}'|awk '{print $1}'`
  echo "^ $DEV | $IP |"
done
echo

echo -e "$HL PCI $HL\n"
lspci |sed 's/^/  /'
echo

echo -e "$HL Filesystems $HL\n"
df -hPT -x tmpfs | awk '{print "| " $1 " | " $2 " | " $3 " | " $7 " |"}'
echo

echo -e "$HL IDE devices $HL\n"

for DEV in `ls -1d /proc/ide/hd* |sed 's/.*\///'`
do
  MODEL=`cat /proc/ide/$DEV/model`
  if [ -e /proc/ide/$DEV/capacity ]; then
    SIZE=`cat /proc/ide/$DEV/capacity`
    SIZE=`expr $SIZE / 2097152`
  else
    if [ -e /sys/block/$DEV/size ]; then
      SIZE=`cat /sys/block/$DEV/size`
      SIZE=`expr $SIZE / 2097152`
    else
      SIZE='(unknown)'
    fi
  fi

  echo "| /dev/$DEV | $MODEL | $SIZE GB |"
done

if [ "$(ls -1d /sys/block/sd* 2> /dev/null)" ]; then
  echo -e "$HL SCSI devices $HL\n"
  for DEV in `ls -1d /sys/block/sd* |sed 's/.*\///'`
  do
    MODEL=`cat /sys/block/$DEV/device/model`
    SIZE=`cat /sys/block/$DEV/size`
    SIZE=`expr $SIZE / 2097152`

    echo "| /dev/$DEV | $MODEL | $SIZE GB |"
  done
  echo
fi
