#!/bin/bash

set -m
set -e

VOLUME_HOME="/var/lib/mysql"
CONF_FILE="/etc/mysql/conf.d/my.cnf"
LOG="/var/log/mysql/error.log"
PID=''

# Set permission of config file
chmod 644 ${CONF_FILE}
chmod 644 /etc/mysql/conf.d/mysqld_charset.cnf

StartMySQL ()
{
	/usr/bin/mysqld_safe ${EXTRA_OPTS} > /dev/null 2>&1 &
    PID=`jobs -p`

    # Time out in 1 minute
    LOOP_LIMIT=60
    for (( i=0 ; ; i++ )); do
        if [ ${i} -eq ${LOOP_LIMIT} ]; then
            echo "Time out. Error log is shown as below:"
            tail -n 100 ${LOG}
            exit 1
        fi
        echo "=> Waiting for confirmation of MySQL service startup, trying ${i}/${LOOP_LIMIT} ..."
        sleep 1
        mysql -uroot -e "status" > /dev/null 2>&1 && break
    done
    echo "${PID}"
}

CreateMySQLUser()
{
	if [ "$MYSQL_PASS" = "**Random**" ]; then
	    unset MYSQL_PASS
	fi

	PASS=${MYSQL_PASS:-$(pwgen -s 12 1)}
	_word=$( [ ${MYSQL_PASS} ] && echo "preset" || echo "random" )
	echo "=> Creating MySQL user ${MYSQL_USER} with ${_word} password"
	echo "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$PASS'"
	mysql -uroot -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$PASS'"
	echo "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION"
	mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION"
	echo "=> Done!"
	echo "========================================================================"
	echo "You can now connect to this MySQL Server using:"
	echo ""
	echo "    mysql -u$MYSQL_USER -p$PASS -h<host> -P<port>"
	echo ""
	echo "Please remember to change the above password as soon as possible!"
	echo "MySQL user 'root' has no password but only allows local connections"
 	echo "========================================================================"
}

OnCreateDB()
{
    if [ "$ON_CREATE_DB" = "**False**" ]; then
        unset ON_CREATE_DB
    else
        echo "Creating MySQL database ${ON_CREATE_DB}"
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${ON_CREATE_DB};"
        echo "Database created!"
    fi
}


# Main
#if [ ${REPLICATION_MASTER} == "**False**" ]; then
#    unset REPLICATION_MASTER
#fi

#if [ ${REPLICATION_SLAVE} == "**False**" ]; then
#    unset REPLICATION_SLAVE
#fi

# Initialize empty data volume and create MySQL user
if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    if [ ! -f /usr/share/mysql/my-default.cnf ] ; then
        cp /etc/mysql/my.cnf /usr/share/mysql/my-default.cnf
    fi
    mysql_install_db || exit 1
    touch /var/lib/mysql/.EMPTY_DB
    echo "=> Done!"
else
    echo "=> Using an existing volume of MySQL"
fi


echo "=> Starting MySQL ..."
STARTOUTPUT=$(StartMySQL)
PID=$(echo ${STARTOUTPUT}|tail -n 1)
tail -F $LOG &
echo "${STARTOUTPUT}"

# Create admin user and pre create database
if [ -f /var/lib/mysql/.EMPTY_DB ]; then
    echo "=> Creating admin user ..."
    #CreateMySQLUser
    #OnCreateDB
    rm /var/lib/mysql/.EMPTY_DB
fi


trap "kill -SIGQUIT $PID" INT
wait


fg
