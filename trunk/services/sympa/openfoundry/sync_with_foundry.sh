#!/bin/sh
(date; /usr/local/sbin/sympa.pl sympa.pl --sync_with_foundry) >> /var/log/sync_with_foundry.log 2>&1
