#!/bin/bash

/root/magento.sh > /var/log/magento-init/magento-stdout.log 2> /var/log/magento-init/magento-stderr.log && /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
