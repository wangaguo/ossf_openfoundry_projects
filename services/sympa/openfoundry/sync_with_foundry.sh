#!/bin/sh
(date; perl sympa.pl --sync_with_foundry) >> /var/log/sync_with_foundry.log 2>&1
