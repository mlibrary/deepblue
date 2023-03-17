#!/bin/bash

# input of the form:
# ./bin/umrdr_migrate_dbdv1.sh c_00000021r w_12345678 ...
# nohup ./bin/umrdr_migrate_dbdv1.sh c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_migrate_dbdv1.sh.out &

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
${DIR}/umrdr_new_content.sh -t umrdr:migrate -b /deepbluedata-prep/DBDv1 "$@"