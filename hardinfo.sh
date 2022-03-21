#!/bin/bash
export LC_NUMERIC="en_US.UTF-8"
source /$HOME/hardinfo/settings_hardinfo.sh
CPU=$(bc <<< "scale=2; 100-$(mpstat | tail -1 | awk 'NF {print $NF}')")

SYSTEM_LOAD=$(cat /proc/loadavg | awk '{print $2}') # load avg за 5 мин.
RAM_TEMP=$(free -g | awk '{print $2,$3}' | awk 'NR==2 {print; exit}')
RAM_TOTAL=$(echo "$RAM_TEMP" | awk '{print $1}')
RAM_USED=$(echo "$RAM_TEMP" | awk '{print $2}')
RAM_PERC=$(bc <<< "scale=2; $RAM_USED/$RAM_TOTAL*100" | grep -oE "[0-9]*" | awk 'NR==1 {print; exit}')

SWAP_TEMP=$(free -g | awk '{print $2,$3}' | awk 'NR==3 {print; exit}')
SWAP_TOTAL=$(echo "$SWAP_TEMP" | awk '{print $1}')
SWAP_USED=$(echo "$SWAP_TEMP" | awk '{print $2}')
SWAP_PERC=$(echo "scale=2; $SWAP_USED/$SWAP_TOTAL*100" | bc | grep -oE "[0-9]*" | awk 'NR==1 {print; exit}')

DISK_TEMP=$(df -h / | awk '{print $2,$3,$5}'| awk 'NR==2 {print; exit}')
DISK_TOTAL=$(echo "$DISK_TEMP" | awk '{print $1}')
DISK_USED=$(echo "$DISK_TEMP" | awk '{print $2}')
DISK_PERC=$(echo "$DISK_TEMP" | awk '{print $3}')


RAMDISK_TEMP=$(df -h | grep ramdisk | awk '{print $2,$3,$5}')
RAMDISK_TOTAL=$(echo "$RAMDISK_TEMP" | awk '{print $1}'| grep -oE "[0-9]*|[0-9]*.[0-9]")
RAMDISK_USED=$(echo "$RAMDISK_TEMP" | awk '{print $2}' | grep -oE "[0-9]*|[0-9]*.[0-9]")
RAMDISK_PERC=$(echo "$RAMDISK_TEMP" | awk '{print $3}' | grep -oE "[0-9]*|[0-9]*.[0-9]")

PUB=${PUB_KEY:0:24}
USED_RAM=""$RAM_USED"G/"$RAM_TOTAL"G ~ "$RAM_PERC"%"
USED_SWAP=""$SWAP_USED"G/"$SWAP_TOTAL"G ~ "$SWAP_PERC"%"
USED_DISK=""$DISK_USED"/"$DISK_TOTAL" ~ "$DISK_PERC"" 
USED_RAMDISK=""$RAMDISK_USED"G/"$RAMDISK_TOTAL"G ~ "$RAMDISK_PERC"%"

if (( $(bc <<< "$RAM_PERC >= $MAX_RAM_PERC") )) || (( $(bc <<< "$SWAP_PERC >= $MAX_SWAP_PERC") )) || (( $(bc <<< "$RAMDISK_PERC >= $MAX_RAMDISK_PERC") ))
then
echo $INFO_ALARM1
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_ALARM"'","text":"<b>'"$INFO_ALARM1"'</b>'"\n[$PUB]"'<code>
RAM >>>> ['"$USED_RAM"']
SWAP >>> ['"$USED_SWAP"']
RAMDISK>>['"$USED_RAMDISK"']</code>","parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
else
echo "Все ok"
fi
if (( $(echo "$(date +%M) < 5" | bc -l) ))
then
echo $TEXT_HARDINFO
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID_HARDINFO"'","text":"<b>'"$TEXT_HARDINFO"'</b>'"\n[$PUB]"'<code>
Used_CPU >>  ['"$CPU"'] 
Srvr_Load >> ['"$SYSTEM_LOAD"'] 
Ram >>> ['"$USED_RAM"'] 
Swap >> ['"$USED_SWAP"'] 
Disk >> ['"$USED_DISK"'] 
Ramdisk>['"$USED_RAMDISK"']</code>",  "parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
fi
