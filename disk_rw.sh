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
    esac
  done
}

process_input_args "$@"

file_size=${file_size:-$DEFAULT_FILE_SIZE}  # size of temporary file used for r/w
block_size=${block_size:-$DEFAULT_BLOCK_SIZE} # size of block
directory=${directory:-$DEFAULT_DIRECTORY}  # directory where iozone creates temporary files.

len=${#file_size}; ((len --))
# echo $len
last_char=${file_size:$len:1} # get size unit
# echo $last_char
file_size=${file_size%$last_char}

for p_num in ${process_num[@]}; do

  i=0
  tmp_files=
  while ((i < $p_num)); do
    tmp_files="${tmp_files} $directory/iozone_tmpfile$i"
    ((i++))
  done

  tmp_file_size="$((file_size / p_num))$last_char"  # each round the total size of all temporary files should be set to value of -f.
  # echo "-t $p_num, -s $tmp_file_size." 
  # echo $tmp_files
  # test write, re-write, read, re-read, random-read, random-write
  iozone -I -p -i 0 -i 1 -i 2 -r $block_size -s $tmp_file_size -R -t $p_num -F $tmp_files 
  echo; echo

done


