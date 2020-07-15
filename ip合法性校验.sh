#!/bin/env bash

#
# Function return true if argument is a valid ipv4 address
#
function isIPv4() {
   local ipv4regexp="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
   if [[ ${1} =~ ${ipv4regexp} ]]; then
      true
   else
      false
  fi
}
#
# Function return true if argument is a valid ipv6 address
#
function isIPv6() {
  local ipv6section="^[0-9a-fA-F]{1,4}$"
  addr="$1"
  number_of_parts=0
  number_of_skip=0
  IFS=':' read -r -a addr <<< "$1"
  if [ ${#addr[@]} -eq 0 ]; then
     return 1
  fi
  for part in "${addr[@]}"; do
    # check to not exceed number of parts in ipv6 address
    if [[ ${number_of_parts} -ge 8 ]]; then
        return 1
    fi
    if [[ ${number_of_parts} -eq 0 ]] && ! [[ ${part} =~ ${ipv6section} ]]; then
        return 1
    fi
    if ! [[ ${part} =~ ${ipv6section} ]]; then
       if ! [[ "$part" == "" ]]; then
          return 1
       else
          # Found empty part, no more than 2 sections '::' are allowed in ipv6 address
          if [[ "$number_of_skip" -ge 1 ]]; then
             return 1
          fi
          ((number_of_skip++))
       fi
    fi
    ((number_of_parts++))
  done
  return 0
}