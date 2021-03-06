#! /bin/bash

if [ "$(ls -A /var/www/magento/repo_volume)" ]; then
    rm -rf /var/www/magento/current
    ln -s /var/www/magento/repo_volume /var/www/magento/current
fi

if [ -d /var/www/magento/shared/var ]; then
    if [ ! -h /var/www/magento/current/var ]; then
        rm -rf /var/www/magento/current/var
    fi

    ln -s /var/www/magento/shared/var /var/www/magento/current/
fi

if [ -d /var/www/magento/shared/media ]; then
    if [ ! -h /var/www/magento/current/pub/media ]; then
        rm -rf /var/www/magento/current/pub/media
    fi

    ln -s /var/www/magento/shared/media /var/www/magento/current/pub/
fi


while [ -z "$DBEXISTS" ]; do
    echo "Check database container exists"
    DBEXISTS=`mysql -h$DB_PORT_3306_TCP_ADDR --port=$DB_PORT_3306_TCP_PORT -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS -e "SHOW STATUS"`
    sleep 1
done

echo "Check magento database exists"
RESULT=`mysql -h$DB_PORT_3306_TCP_ADDR --port=$DB_PORT_3306_TCP_PORT -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS -e "SHOW DATABASES LIKE '$DB_ENV_MYSQL_DBNAME'"`

if [ -z "$RESULT" ]; then
    if [ -f /var/www/magento/shared/sql/magento.sql.gz ]; then
        echo "Create new magento database"
        mysql -h$DB_PORT_3306_TCP_ADDR --port=$DB_PORT_3306_TCP_PORT -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS -e "CREATE DATABASE $DB_ENV_MYSQL_DBNAME;"

        gunzip -kf /var/www/magento/shared/sql/magento.sql.gz

        echo "Apply magento.sql dump to magento"
        mysql -h$DB_PORT_3306_TCP_ADDR --port=$DB_PORT_3306_TCP_PORT -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS $DB_ENV_MYSQL_DBNAME < /var/www/magento/shared/sql/magento.sql

        gzip /var/www/magento/shared/sql/magento.sql
    else
        while [ -z "$RESULT" ]; do
            echo "Check database container exists"
            RESULT=`mysql -h$DB_PORT_3306_TCP_ADDR --port=$DB_PORT_3306_TCP_PORT -u$DB_ENV_MYSQL_USER -p$DB_ENV_MYSQL_PASS -e "SHOW DATABASES LIKE '$DB_ENV_MYSQL_DBNAME'"`
            sleep 1
        done
    fi
fi



cd /var/www/magento/current

magento maintenance:enable

cd /var/www/magento/current/app/etc/
cp ./local.xml.widgento.template ./local.xml.live.tmp
sed -i "s/{{db_host}}/${DB_PORT_3306_TCP_ADDR}:${DB_PORT_3306_TCP_PORT}/g" ./local.xml.live.tmp
sed -i "s/{{db_user}}/$DB_ENV_MYSQL_USER/g" ./local.xml.live.tmp
sed -i "s/{{db_pass}}/$DB_ENV_MYSQL_PASS/g" ./local.xml.live.tmp
sed -i "s/{{db_name}}/$DB_ENV_MYSQL_DBNAME/g" ./local.xml.live.tmp
sed -i "s/{{session_host}}/$SESSION_PORT_11211_TCP_ADDR/g" ./local.xml.live.tmp
sed -i "s/{{session_port}}/$SESSION_PORT_11211_TCP_PORT/g" ./local.xml.live.tmp
sed -i "s/{{cache_host}}/$CACHE_PORT_11211_TCP_ADDR/g" ./local.xml.live.tmp
sed -i "s/{{cache_port}}/$CACHE_PORT_11211_TCP_PORT/g" ./local.xml.live.tmp
mv ./local.xml.live.tmp ./local.xml

cd /var/www/magento/current/
chmod 0777 -R /var/www/magento/current/var
magento setup:db-schema:upgrade
magento setup:db-data:upgrade
./n98-magerun2.phar dev:log --on --global
rm -rf var/cache/
./n98-magerun2.phar cache:flush

chown -R magento:dev /var/www/magento/current/

magento maintenance:disable
