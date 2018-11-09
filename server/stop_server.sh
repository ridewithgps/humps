#!/bin/bash
pidfile="/var/www/humps/current/server/tmp/pids/unicorn.pid"

if [[ -f $pidfile ]]; then
    kill `cat $pidfile`
fi
