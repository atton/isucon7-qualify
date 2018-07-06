#!/bin/sh
cd `dirname $0`

fuser -k 9292/tcp
bundle exec puma -q -e production -d -t 16
