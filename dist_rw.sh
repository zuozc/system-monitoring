#!/bin/bash

# usage: disk_rw_test.sh -f=number[m/g] -b=number
# -f, size of file for test, a number with a [m/g] means KB/GB
# -b, blocks for record, a number

command -v iozone >/dev/null 2>&1 || { echo "iozone has not been installed yet, and program will install it now."; sudo apt-get install -y iozone3; }

process_num=(1 5 10 20 50)  # number of processes used in test
DEFAULT_FILE_SIZE="`free -m | grep "Mem:" | awk '{print $2}'`m"  # default size of temporary file used for r/w, set it to memory size.
DEFAULT_BLOCK_SIZE=4096 # default number of record blocks

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
    esac
  done
}

process_input_args "$@"

file_size=${file_size:-$DEFAULT_FILE_SIZE}  # size of temporary file used for r/w
block_size=${block_size:-$DEFAULT_BLOCK_SIZE} # number of record blocks

# [[ -e disk_rw_test.log ]] && rm disk_rw_test.log

echo; echo "Block size = $block_size, file size = $file_size for disk r/w test." 
echo "Output is in Kbytes/sec"; echo

for p_num in ${process_num[@]}; do

  i=0
  tmp_files=
  while ((i < $p_num)); do
    tmp_files="${tmp_files} tmpfile$i"
    ((i++))
  done

  echo "$p_num processes: " 
  #echo $tmp_files
  
  # test write, re-write, read, re-read, random-read, random-write
  iozone -i 0 -i 1 -i 2 -r $block_size -s $file_size -R -t $p_num -F $tmp_files | grep "Initial write\|Rewrite\|Read\|Re-read\|Random read\|Random write"
  echo; echo

done


