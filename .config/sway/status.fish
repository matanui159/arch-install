#!/usr/bin/env fish
while true
   set datetime (date '+%A %B %e - %l:%M %P')
   set batfile /sys/class/power_supply/BAT0/capacity
   if test -f $batfile
      set bat (printf %+3s (cat $batfile))%
   else
      set bat [PC]
   end
   echo "$datetime - $bat "
   sleep 1
end
