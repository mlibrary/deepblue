#!/bin/bash
#
# cd into current directory and:
# nohup ./bin/scheduler.sh 2>&1 >> ./log/scheduler.sh.out &
# tail -f ./log/scheduler.sh.out
#
RAILS_ENV=production bundle exec rake resque:scheduler
