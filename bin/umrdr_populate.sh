#!/bin/bash

# input of the form:
# ./bin/umrdr_populate.sh c_00000021r w_12345678 ...
# nohup ./bin/umrdr_populate.sh c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_populate.sh.out &

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
${DIR}/umrdr_new_content.sh -t umrdr:populate "$@"