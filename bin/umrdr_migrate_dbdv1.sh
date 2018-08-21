#!/bin/bash

# input of the form:
# ./bin/umrdr_migrate.sh c_00000021r w_12345678 ...
# nohup ./bin/umrdr_migrate.sh c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_migrate.sh.out &

base_dir="/deepbluedata-prep/DBDv1/"
task="umrdr:migrate"
prefix=""
postfix="_populate"
ingester=fritx@umich.edu

ts=$(date "+%Y%m%d%H%M%S")
echo "Begin: $ts"
for arg in "$@"; do
  echo
  echo "${arg}"
  base_file="${prefix}${arg}${postfix}"
  input_file="${base_dir}${base_file}.yml"
  if [ -f $input_file ]; then
    echo "Input File: '${input_file}' exists."
  else
    echo "WARNING Input File: '${input_file}' not found."
    continue
  fi
  log_file="${base_dir}${base_file}.out"
  ts=$(date "+%Y%m%d%H%M%S")
  if [ -f $log_file ]; then
    backup_log_file="${base_dir}${base_file}/${ts}_${base_file}.out"
    echo "Log File: '${log_file}' exists, move it to backup ${backup_log_file}"
    mv ${log_file} ${backup_log_file}
  else
    echo "Log File: '${log_file}' not found."
  fi
  if [ -z "${ingester}" ]; then
  	bundle exec rake ${task}[${input_file}] 2>&1 | tee ${log_file}
  else
  	bundle exec rake ${task}[${input_file},${ingester}] 2>&1 | tee ${log_file}
  fi
done
echo
ts=$(date "+%Y%m%d%H%M%S")
echo "End: $ts"