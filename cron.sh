#!/bin/sh

/root/magento.sh > /var/log/magento-init/magento-stdout.log 2> /var/log/magento-init/magento-stderr.log && cron -f -L 15
