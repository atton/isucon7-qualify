#!/bin/bash

DB_DIR=$(cd $(dirname $0) && pwd)
cd $DB_DIR

mysql -uroot -e "DROP DATABASE IF EXISTS isubata; CREATE DATABASE isubata;"
mysql -uroot isubata < ./isubata.sql
mysql -uroot -e "set global innodb_flush_log_at_trx_commit = 2;"
# zcat /home/isucon/isubata/bench/isucon7q-initial-dataset.sql.gz | sudo mysql isubata
