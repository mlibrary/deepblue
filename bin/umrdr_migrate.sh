#!/bin/bash

# input of the form:
# ./bin/umrdr_migrate.sh -b /deepbluedata-prep/ c_00000021r w_12345678
# ./bin/umrdr_migrate.sh -b /deepbluedata-prep/ -i fritx -v c_00000021r w_12345678 w_123
# ./bin/umrdr_migrate.sh -b /deepbluedata-prep/DBDv1/ -v c_00000021r w_12345678 w_123
# nohup ./bin/umrdr_migrate.sh -b /deepbluedata-prep/ c_00000021r w_12345678 2>&1 > ./log/20180811.umrdr_migrate.sh.out &

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
${DIR}/umrdr_new_content.sh -t umrdr:migrate "$@"