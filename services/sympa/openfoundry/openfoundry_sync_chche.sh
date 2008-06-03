#!/bin/sh
(date; perl -MOpenFoundry -e 'OpenFoundry::Impl::OF::refresh') >> /var/log/sync_cache_foundry.log 2>&1
