#!/bin/bash
pidfile="/var/run/humps/humps-unicorn.pid"

if [[ -f $pidfile ]]; then
    kill `cat $pidfile`
fi
