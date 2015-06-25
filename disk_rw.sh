#!/bin/bash

# check disk I/O performance
#
# usage: disk_rw_test.sh -f=number[m/G] -b=number -d=directory
# -f, size of file for test, a number with a [m/g] means KB/GB
# -b, blocks for record, a number
# -d, the absolute directory where temparary files will be created.

command -v iozone >/dev/null 2>&1 || { echo "iozone has not been installed yet, and program will install it now."; sudo apt-get install -y iozone3; }

process_num=(1 5 10 20 50)  # number of processes used in test
DEFAULT_FILE_SIZE=3200m  # default size of temporary file used for r/w
DEFAULT_BLOCK_SIZE=4 # default size of block
DEFAULT_DIRECTORY="`pwd`" # default directory where iozone creats temporary files
DEFAULT_LOG="iozone_disk_rw.$(date +%Y%m%d%H%M).log"

# process argments
process_input_args() {
  for opt in "$@"; do
    case $opt in
      -f=*)
        file_size="${opt#*=}"
        shift
        ;;

      -b=*)
        block_size="${opt#*=}"
        shift
        ;;

      -d=*)
        directory="${opt#*=}"
        shift
        ;;

      --log=*)
        log_file="${opt#*=}"
        shift
        ;;
    esac
  done
}

process_input_args "$@"

file_size=${file_size:-$DEFAULT_FILE_SIZE}  # size of temporary file used for r/w
block_size=${block_size:-$DEFAULT_BLOCK_SIZE} # size of block
directory=${directory:-$DEFAULT_DIRECTORY}  # directory where iozone creates temporary files.
log_file=${log_file:-$DEFAULT_LOG}

len=${#file_size}; ((len --))
# echo $len
last_char=${file_size:$len:1} # get size unit
# echo $last_char
file_size=${file_size%$last_char}

for p_num in ${process_num[@]}; do

  i=0
  tmp_files=
  while ((i < $p_num)); do
    tmp_files="${tmp_files} $directory/iozone_process_logsile$i"
    ((i++))
  done

  tmp_file_size="$((file_size / 1))$last_char"  # each round the total size of all temporary files should be set to value of -f.
  # echo "-t $p_num, -s $tmp_file_size." 
  # echo $tmp_files
  # test write, re-write, read, re-read, random-read, random-write
  iozone -I -p -i 0 -i 1 -i 2 -r $block_size -s $tmp_file_size -R -t $p_num -F $tmp_files > $log_file

done

# send mail when check done.
recipients="bjzuozc@cn.ibm.com"
subject="IOZone - I/O Performance Test"
# from="your_mail@something.com"

# another way to process logs
process_logs () {
  cat $log_file | grep "Initial write\|Rewrite\|Read\|Re-read\|Random read\|Random write" > tmp.log
  
  while read line; do
  
    tmp=$(($i % 6))
    if [[ $tmp -eq 0 ]]; then 
      p_num=${process_num[$(($i / 6))]}
      tmp_size=$((file_size / p_num))
      message_txt="$message_txt\nprocess number: $p_num, file size: $tmp_size$last_char\n"
    fi
    ((i += 1))

  done < tmp.log

  rm -f tmp.log
}

message_txt="\ntotal file size: ${file_size}${last_char}\n"
message_txt="${message_txt}""command: iozone -I -p -i 0 -i 1 -i 2 -r block_size -s file_size -R -t process_num\n"

IFS=$'\n'
i=0
for line in `cat $log_file | grep "Initial write\|Rewrite\|Read\|Re-read\|Random read\|Random write"`; do

  tmp=$(($i % 6))
  if [[ $tmp -eq 0 ]]; then
    p_num=${process_num[$(($i / 6))]}
    tmp_size=$((file_size / p_num))
    message_txt="$message_txt\nprocess number: $p_num, file size: $tmp_size$last_char\n"
  fi
  message_txt="$message_txt$line\n"
  #echo $message_txt
  ((i += 1))
  #echo $line
done

# process_logs

# echo "i = $i"
echo -e "$message_txt"
# echo -e $message_txt | sendmail "$recipients" << EOF
sendmail "$recipients" << EOF
subject:$subject
`echo -e $message_txt`
EOF
