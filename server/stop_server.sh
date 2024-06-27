#!/bin/bash
pidfile="/tmp/pids/unicorn.pid"

if [[ -f $pidfile ]]; then
    kill `cat $pidfile`
fi
