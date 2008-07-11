#!/bin/sh
(date; perl -MOpenFoundry -e 'OpenFoundry::refresh("sympa")') >> /var/log/sync_cache_foundry.log 2>&1
