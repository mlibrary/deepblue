#!/bin/bash

# input of the form:
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ c_00000021r w_12345678
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ -i fritx -v c_00000021r w_12345678 w_123
# ./bin/umrdr_new_content.sh -b /deepbluedata-prep/DBDv1/ -v c_00000021r w_12345678 w_123
# nohup ./bin/umrdr_new_content.sh -b /deepbluedata-prep/ c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_new_content.sh.out &

shell_name="umrdr_new_content.sh"
original_args="$@"
stop_file="$PWD/stop_umrdr_new_content"
pid_stop_file="$PWD/$$_stop_umrdr_new_content"
base_dir="/deepbluedata-prep/" # default value for -b / --base_dir
ingester="fritx@umich.edu"     # default value for -i / --ingester
dry_run=false                  # default value for -d / --dry_run
multi=false                    # default value for -m / --multi
prefix=""                      # default value for prefix ( -c / --collections ) ( -w / --works )
postfix="_populate"            # default value for -p / --postfix
task="umrdr:build"             # default value for -t / --task
verbose=true                   # default value for -v / --verbose
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
    -m|--multi)
    multi=true
    shift # past argument
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
  echo "# stop_file      = '${stop_file}'"
  echo "# pid_stop_file  = '${pid_stop_file}'"
  echo "# dry_run   (-d) = ${dry_run}"
  echo "# ingester  (-i) = '${ingester}'"
  echo "# multi     (-m) = '${multi}'"
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
if [ "${multi}" = "true" ]; then
  ${verbose} && echo "#"
  ${verbose} && echo "# processing '$@' ..."
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
      ${verbose} && echo "bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}"
      bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}
    fi
  fi
else
  for arg in "$@"; do
    if [ -f $stop_file ]; then
      not_processed+=("${arg}")
      continue
    elif [ -f $pid_stop_file ]; then
      not_processed+=("${arg}")
      continue
    elif [ "${verbose}" = "true" ]; then
      echo "# To stop processing: touch ${pid_stop_file}"
    fi
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
      if [ -d "${base_dir}${base_file}" ]; then
        backup_log_file="${base_dir}${base_file}/${ts}_${base_file}.out"
      else
        backup_log_file="${base_dir}${ts}_${base_file}.out"
      fi
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
        ${verbose} && echo "bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}"
        bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}
      fi
    fi
  done
  if [ -f $stop_file ]; then
    echo "# Stop file found: ${stop_file}"
  fi
  if [ -f $pid_stop_file ]; then
    echo "# Stop file found: ${pid_stop_file}"
  fi
fi
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
