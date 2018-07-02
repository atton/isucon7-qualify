#!/bin/bash

DB_DIR=$(cd $(dirname $0) && pwd)
cd $DB_DIR

mkdir -p /mnt/ramdisk
mount -t tmpfs -o size=2G tmpfs /mnt/ramdisk/
mkdir -p /mnt/ramdisk/mysql
mkdir -p /mnt/ramdisk/tmp
chown mysql: /mnt/ramdisk/mysql
chown mysql: /mnt/ramdisk/tmp
/usr/bin/rsync -avz --delete /var/lib/mysql/ /mnt/ramdisk/mysql/
systemctl start mysql

mysql -uroot -e "DROP DATABASE IF EXISTS isubata; CREATE DATABASE isubata;"
mysql -uroot isubata < ./isubata.sql
# zcat /home/isucon/isubata/bench/isucon7q-initial-dataset.sql.gz | sudo mysql isubata
