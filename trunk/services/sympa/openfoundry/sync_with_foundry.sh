#!/bin/sh
(date; perl -MOpenFoundry -e 'OpenFoundry::Impl::OF::sync_with_foundry') >> /var/log/sync_with_foundry.log 2>&1
