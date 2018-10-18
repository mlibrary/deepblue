#!/bin/bash

# input of the form:
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ c_00000021r w_12345678
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ -i fritx -v c_00000021r w_12345678 w_123
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/DBDv1/ -v c_00000021r w_12345678 w_123
# nohup ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_new_content.sh.out &

shell_name="umrdr_new_content.sh"
original_args="$@"
base_dir="/deepbluedata-prep/" # default value for -b / --base_dir
ingester="fritx@umich.edu"     # default value for -i / --ingester
dry_run=false                  # default value for -d / --dry_run
prefix=""                      # default value for prefix ( -c / --collections ) ( -w / --works )
postfix="_populate"            # default value for -p / --postfix
task="umrdr:build"             # default value for -t / --task
verbose=true                  # default value for -v / --verbose
not_processed=()

ts=$(date "+%Y%m%d%H%M%S")
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
args=()
while [[ $# -gt 0 ]]
  do
  key="$1"
  case $key in
    -b|--base_dir)
    base_dir="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dry_run)
    dry_run=true
    shift # past argument
    ;;
    -c|--collections)
    prefix="c_"
    shift # past argument
    ;;
    -i|--ingester)
    ingester="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--postfix)
    postfix="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--task)
    task="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--verbose)
    verbose=true
    shift # past argument
    ;;
    -w|--works)
    prefix="w_"
    shift # past argument
    ;;
    *)    # unknown option
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
  esac
done
set -- "${args[@]}" # restore positional parameters

if [ "${verbose}" = "true" ]; then
  echo "#"
  echo "# ${shell_name} ${original_args}"
  echo "#"
fi

if [ "${verbose}" = "true" ]; then
  echo "# base_dir  (-b) = '${base_dir}'"
  echo "# dry_run   (-d) = ${dry_run}"
  echo "# ingester  (-i) = '${ingester}'"
  echo "# prefix (-c/-w) = '${prefix}'"
  echo "# postfix   (-p) = '${postfix}'"
  echo "# task      (-t) = '${task}'"
  echo "# verbose   (-v) = ${verbose}"
  echo "# rest of args = '$@'"
  echo "#"
fi

if [ "${dry_run}" = "true" ]; then
  ${verbose} && echo "# This is a dry run."
fi
echo "# Begin: $ts"
for arg in "$@"; do
  ${verbose} && echo "#"
  ${verbose} && echo "# processing '${arg}' ..."
  base_file="${prefix}${arg}${postfix}"
  input_file="${base_dir}${base_file}.yml"
  if [ -f $input_file ]; then
    ${verbose} && echo "# Input File: '${input_file}' exists."
  else
    not_processed+=("${arg}")
    echo "# WARNING Input File: '${input_file}' not found."
    continue
  fi
  log_file="${base_dir}${base_file}.out"
  ts=$(date "+%Y%m%d%H%M%S")
  if [ -f $log_file ]; then
    backup_log_file="${base_dir}${base_file}/${ts}_${base_file}.out"
    ${verbose} && echo "# Log File: '${log_file}' exists, move it to backup ${backup_log_file}"
    if [ "${dry_run}" = "true" ]; then
      echo "mv ${log_file} ${backup_log_file}"
    else
      mv ${log_file} ${backup_log_file}
    fi
  else
    ${verbose} && echo "# Log File: '${log_file}' not found."
  fi
  if [ -z "${ingester}" ]; then
  	if [ "${dry_run}" = "true" ]; then
  	  echo "bundle exec rake ${task}[${input_file}] 2>&1 | tee ${log_file}"
  	else
  	  bundle exec rake ${task}[${input_file}] 2>&1 | tee ${log_file}
  	fi
  else
  	if [ "${dry_run}" = "true" ]; then
  	  echo "bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}"
  	else
  	  bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}
  	fi
  fi
done
${verbose} && echo "#"
ts=$(date "+%Y%m%d%H%M%S")
echo "# End: $ts"
if [ "${verbose}" = "true" ]; then
  if [ "${dry_run}" = "true" ]; then
    echo "# This was a dry run."
  fi
  echo "#"
  echo "# finished running ${shell_name}"
  echo "#"
fi
if [ "" = "${not_processed}" ]; then
  :
else
  echo "# WARNING: failed to ${task}: ${not_processed}"
fi
