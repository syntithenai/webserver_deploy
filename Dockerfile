FROM ubuntu:16.04
MAINTAINER Steve Ryan <steve@2pisoftware.com>
# DEFAULT LOCAL MYSQL SERVER
ENV RDS_HOSTNAME=localhost RDS_USERNAME=admin RDS_PASSWORD=admin RDS_DB_NAME=cmfive STARTUP_SQL=
  
# INTEGRATE PHUSION BASE IMAGE STEPS
ADD ./src/baseimage/ /bd_build/

RUN chmod +rx -R /bd_build/; /bd_build/prepare.sh && \
 	/bd_build/system_services.sh && \
 	/bd_build/utilities.sh && \
 	/bd_build/cleanup.sh


RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

RUN export DEBIAN_FRONTEND="noninteractive" ; apt-get  --allow-unauthenticated update && apt-get install  -yq  --force-yes software-properties-common python-software-properties git php-cli  nano  php-cli git nginx php-mysql curl php-curl git php-cli php-fpm php-mysql php-pgsql php-curl php-gd php-mcrypt php-intl php-imap php-tidy  php-mbstring php7.0-mbstring php-gettext  letsencrypt mysql-server-5.7 pwgen && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; 

# CONFIGURE NGINX
RUN mkdir -p /var/log/nginx;  echo "daemon off;" >> /etc/nginx/nginx.conf; ln -sf /dev/stdout /var/log/nginx/localhost.com-access.log; ln -sf /dev/stderr /var/log/nginx/localhost.com-error.log
EXPOSE 80 443

# MYSQL INSTALL AND SETUP
EXPOSE 3306

# LOCALES
RUN locale-gen de_DE.UTF-8;  locale-gen fr_FR.UTF-8; locale-gen ja_JP.UTF-8;  locale-gen es_ES.UTF-8; locale-gen ru_RU.UTF-8; locale-gen gd_GB.UTF-8; locale-gen nl_NL.UTF-8; locale-gen zh_CN.UTF-8;

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# PHP CONFIG
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cgi.log/' /etc/php/7.0/fpm/php.ini && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cli.log/' /etc/php/7.0/cli/php.ini && \
    sed -i 's/^key_buffer\s*=/key_buffer_size =/' /etc/mysql/my.cnf


# nginx
ADD ./src/nginx/default /etc/nginx/sites-enabled/default
ADD ./src/nginx/run /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

#ssl
#ADD ./src/nginx/generatessl.sh /generatessl.sh
#RUN chmod +x /generatessl.sh
#ADD ./src/nginx/nginx.crt /nginx.crt
#ADD ./src/nginx/nginx.key /nginx.key
#ENV SSL_CERT=/root/nginx.crt
#ENV SSL_KEY=/root/nginx.key

# php
RUN mkdir /etc/service/phpfpm
ADD ./src/nginx/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run
ADD ./src/php/www.conf /etc/php/7.0/fpm/pool.d/

# mysql
RUN touch /var/lib/mysql/.EMPTY_DB; mkdir /etc/service/mysql
ADD ./src/mysql/my.cnf /etc/mysql/conf.d/my.cnf
ADD ./src/mysql/mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf
ADD ./src/mysql/import_sql.sh /import_sql.sh
RUN chmod +x /import_sql.sh
ADD ./src/mysql/run.sh /etc/service/mysql/run
RUN chmod +x /etc/service/mysql/run
ENV MYSQL_USER=admin
ENV PASS=admin

ENV TERM xterm
RUN mkdir /run/php

# persist database 
VOLUME [ "/var/lib/mysql"]

# phusion/baseimage init script
CMD ["/sbin/my_init"]
