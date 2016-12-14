#!/bin/bash
chmod -R 777 /var/www/cmfive/storage
chmod -R 777 /var/www/cmfive/cache
chmod -R 777 /var/www/cmfive/log
chmod -R 777 /var/www/cmfive/uploads
chmod -R 777 /var/www/cmfive/backups

		
set -m
set -e

# load env vars
#. /etc/container_environment.sh


# DATABASE
if [ ! -f /cmfive_install_db_complete ]; then
	# Start and wait for database server. Time out in 1 minute
	LOOP_LIMIT=60
	for (( i=0 ; ; i++ )); do
		if [ ${i} -eq ${LOOP_LIMIT} ]; then
			echo "Time out. Error log is shown as below:"
			tail -n 100 ${LOG}
			exit 1
		fi
		echo "=> Waiting for confirmation of MySQL service startup, trying ${i}/${LOOP_LIMIT} ..."
		sleep 1
		if [ -n "$RDS_HOSTNAME" ]
        then
			mysql -h$RDS_HOSTNAME -u$RDS_USERNAME -p$RDS_PASSWORD  -e "status" > /dev/null 2>&1 && break
        else 
			mysql -u$MYSQL_USER -p$MYSQL_PASS  -e "status" > /dev/null 2>&1 && break
		fi
	done
	# extra wait once db is live for admin user to be created
	sleep 5
	
	# IMPORT SQL
    for FILE in ${STARTUP_SQL}; do
	    echo "=> Importing SQL file ${FILE}"
        if [ -n "$RDS_HOSTNAME" ]
        then
			mysql -h$RDS_HOSTNAME -u$RDS_USERNAME -p$RDS_PASSWORD "$RDS_DB_NAME" < "${FILE}"
        else 
			mysql -u$MYSQL_USER -p$MYSQL_PASS "$ON_CREATE_DB" < "${FILE}"
		fi
    done
    touch /cmfive_install_db_complete
fi





if [ ! -f /cmfive_install_complete ]; then


	# UPDATE GIT VERSION BASED ON ENV VARS
	cd /var/www/cmfive
	if [ -n "$GIT_CMFIVE_TAG" ]; then
		git checkout -f tags/$GIT_CMFIVE_TAG
	elif [ -n "$GIT_CMFIVE_BRANCH" ]; then
		git checkout -f $GIT_CMFIVE_BRANCH
	fi 
	
	# SYMLINK ALL CMFIVE GENERATED FILES INTO SINGLE LOCATION FOR EASY HOST MOUNT
	# NOTE THAT THIS MEANS THAT IT IS NOT POSSIBLE TO HOST MOUNT THE WHOLE CMFIVE FOLDER ON WINDOWS
	# BECAUSE SYMLINKS FILE
	# THE DEV IMAGE SKIPS THIS STEP SO CAN BE USED TO MOUNT AN ENTIRE CMFIVE INSTALL FROM THE HOST
	if [ ! -f /cmfive_symlink_complete ]; then
		# single location for cmfive generated files
		mkdir -p /data
		mkdir -p /data/log
		mkdir -p /data/uploads
		mkdir -p /data/backups
		mkdir -p /data/storage
		mkdir -p /data/storage/logs
		mkdir -p /data/storage/backup
		mkdir -p /data/storage/session
		rm -rf /var/www/cmfive/log
		ln -s /data/log /var/www/cmfive/log
		rm -rf /var/www/cmfive/uploads
		ln -s /data/uploads /var/www/cmfive/uploads 
		rm -rf /var/www/cmfive/storage
		ln -s /data/storage /var/www/cmfive/storage
		rm -rf /var/www/cmfive/backups
		ln -s /data/backups /var/www/cmfive/backups
		chmod -R 777 /data
		touch /cmfive_symlink_complete
	fi

	
	#COMPOSER
	cd /var/www/cmfive/system
	echo "Update composer"
	php -f /updatecomposer.php
	export COMPOSER_HOME=/var/www
	php composer.phar update
	cd -

	git config user.name $GIT_USER_NAME
	git config user.email $GIT_USER_EMAIL
	git config core.fileMode false 
	
	
	touch /cmfive_install_complete
fi

#PERMS
chmod -R 777 /var/www/cmfive/cache
chmod -R 777 /var/www/cmfive/storage
chmod -R 777 /var/www/cmfive/cache
chmod -R 777 /var/www/cmfive/log
chmod -R 777 /var/www/cmfive/uploads
chmod -R 777 /var/www/cmfive/backups
