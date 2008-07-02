#!/bin/sh
(date; perl /usr/local/sbin/sympa.pl --sync_with_foundry) >> /var/log/sync_with_foundry.log 2>&1
