#!/bin/sh
# origin: https://unix.stackexchange.com/questions/401785/ps-output
# orinal suggestion
# ps -eo lstart,pid,cmd --sort=start_time | awk '{ cmd="date -d\""$1 FS $2 FS $3 FS $4 FS $5"\" +\047%Y-%m-%d %H:%M:%S\047"; cmd | getline d; close(cmd); $1=$2=$3=$4=$5=""; printf "%s\n",d$0 }'

# https://www.degraeve.com/reference/asciitable.php
# https://www.shellhacks.com/awk-print-column-change-field-separator-linux-bash/
PROCESS='bash'

ps -eo lstart,user,cmd --sort=start_time |grep $PROCESS|grep -v grep| awk '{print  $1 " " $2 " " $3" " $4" "$5 "," $6 "," $7 }' | awk 'BEGIN{FS=","} {DATE_COMMAND = "date -d \"" $1 "\" +%s"; USER=$2 ; COMMAND = $3; DATE_COMMAND|getline DATE_EPOCH; print DATE_EPOCH FS USER FS COMMAND; close(DATE_COMMAND)}'

# see also:
# http://www.cyberforum.ru/shell/thread2577520.html
# their suggestion is to use the change in the elapse output:
# ps -eo 'user,etime' | awk '$2 ~ /-/ {print $1}' | sort -u
# ps -eo start=,user= --sort=user | sed -n 's/^\s.*\s//p' | uniq

