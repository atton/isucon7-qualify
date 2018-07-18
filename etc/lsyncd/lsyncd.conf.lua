settings {
    logfile = "/var/log/lsyncd.log",
    statusFile = "/var/tmp/lsyncd.stat",
    statusInterval = 1,
    maxDelays = 0,
}
sync {
    default.rsync,
    source = "/home/atton/isucon7-qualify/webapp/public/icons",
    target = "atton@lsyncd-destination-server:/home/atton/isucon7-qualify/webapp/public/icons",
    rsync = {
        rsh = "/usr/bin/ssh -l atton -i /home/atton/.ssh/id_rsa",
        rsync_path = "sudo rsync"
    }
}
