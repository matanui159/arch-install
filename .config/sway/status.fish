#!/usr/bin/env fish
while true
   set date (date '+%a %b %d - %I:%M')
   set battery (cat /sys/class/power_supply/BAT0/capacity)
   echo "$date - $battery%"
   sleep 1
end
