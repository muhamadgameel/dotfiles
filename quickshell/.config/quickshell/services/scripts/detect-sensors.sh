#!/bin/sh
# Prints "cpu|gpu|battery <type> <path>", one line per sensor found.

for h in /sys/class/hwmon/hwmon*/; do
  [ -r "$h/name" ] || continue
  n=$(cat "$h/name" 2>/dev/null) || continue
  case "$n" in
    coretemp | k10temp | zenpower | zenpower3)
      f=""
      for lbl in "$h"temp*_label; do
        [ -e "$lbl" ] || continue
        case "$(cat "$lbl" 2>/dev/null)" in
          "Package id 0" | Tctl | Tdie)
            f="${lbl%_label}_input"
            break
            ;;
        esac
      done
      [ -n "$f" ] && [ -e "$f" ] || f="${h}temp1_input"
      [ -e "$f" ] && echo "cpu $n $f"
      ;;
    amdgpu)
      [ -e "${h}temp1_input" ] && echo "gpu amd ${h}temp1_input"
      ;;
  esac
done
for b in /sys/class/power_supply/*/; do
  [ "$(cat "$b/type" 2>/dev/null)" = "Battery" ] || continue
  [ -e "${b}energy_full_design" ] || continue
  echo "battery sysfs $b"
  break
done
