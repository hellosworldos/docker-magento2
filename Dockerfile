FROM hellosworldos/webserver:xenial

ADD /etc/nginx/magento_rewrites.conf /etc/nginx/magento_rewrites.conf
ADD /etc/nginx/magento_security.conf /etc/nginx/magento_security.conf
ADD /etc/nginx/conf.d/magento.conf /etc/nginx/conf.d/magento.conf
ADD /magento.sh /root/magento.sh
ADD /cron.sh /root/cron.sh
ADD /init.sh /root/init.sh
ADD /etc/cron.d/magento.crontab /etc/cron.d/magento.crontab

RUN chmod +x /root/magento.sh \
    && chmod +x /root/cron.sh \
    && groupadd dev \
    && useradd -G dev magento \
    && usermod -a -G dev www-data \
    && mkdir -p /var/www/magento/shared/var \
    && chmod 0777 -R /var/www/magento/shared/var \
    && mkdir -p /var/www/magento/shared/media \
    && mkdir -p /var/log/magento-init

VOLUME ["/var/www/magento/repo_volume"]
VOLUME ["/var/www/magento/shared/var", "/var/www/magento/shared/media"]
VOLUME ["/var/www/magento/shared/sql"]

CMD ["/root/init.sh"]
