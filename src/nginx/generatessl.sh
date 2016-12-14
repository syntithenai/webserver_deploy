#!/bin/bash

#CONFIG
#SSL_HOST=aws.syntithenai.com
# PREGENERATED SSL CERTS
#SSL_KEY=
#SSL_CERT=

# INSTALL
# ensure $SSL_HOST DNS is delegated to the instance
## INSTALL CODE SERVER
# ensure proxy server supports ssl and certs folder
# docker run -d -p 80:80 -p 443:443 -v /etc/nginxcerts:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
## INSTALL AWS

##RUN
# specify SSL_HOST env var to generate certificate
#
# use a volume mount to share certs with nginx-proxy on code server
# docker run --name myssl -d -P -e VIRTUAL_HOST=myssl.code.2pisoftware.com -e SSL_HOST=myssl.code.2pisoftware.com -v /etc/nginxcerts:/etc/nginxcerts 2pisoftware/cmfive
# 
# SSL_CERT and SSL_KEY can contain the path to pregenerated key and certificate files.
# the files would need to be added using ADD in the Dockerfile or volume mounts at runtime.
# docker run --name STEVE_cmfive -d -P -e VIRTUAL_HOST=aws.code.2pisoftware.com -e SSL_HOST=aws.code.2pisoftware.com -e SSL_CERT=/etc/nginxcerts/aws.code.2pisoftware.com.crt -e SSL_KEY=/etc/nginxcerts/aws.code.2pisoftware.com.key -v /etc/nginxcerts:/etc/nginxcerts steve_cmfive

if [ -n "$SSL_HOST" ]; then
	# generate a certficate if required
	if [ -s "$SSL_CERT" -a -s "$SSL_KEY" ]; then 
		# NGINX-PROXY
		# copy certs to volume for nginx-proxy
		if [ -e /etc/nginxcerts ]; then
			cp $SSL_CERT /etc/nginxcerts/$SSL_HOST.crt;
			cp $SSL_KEY /etc/nginxcerts/$SSL_HOST.key;
		fi
	else
		SSL_CERT=/etc/letsencrypt/live/$SSL_HOST/fullchain.pem
		SSL_KEY=/etc/letsencrypt/live/$SSL_HOST/privkey.pem
		letsencrypt certonly --webroot  --webroot-path=/var/www --domains=$SSL_HOST --register-unsafely-without-email --agree-tos -n;
		# NGINX-PROXY
		# copy certs to volume for nginx-proxy
		if [ -e /etc/nginxcerts ]; then
			cp $SSL_CERT /etc/nginxcerts/$SSL_HOST.crt;
			cp $SSL_KEY /etc/nginxcerts/$SSL_HOST.key;
		fi
	fi
	
	# in any case support STANDALONE SSL
	# copy certs to standard location for nginx
	mkdir /etc/nginx/certs
	if [ -s "$SSL_CERT" -a -s "$SSL_KEY" ]; then 
		cp $SSL_CERT /etc/nginx/certs/crt.pem;
		cp $SSL_KEY /etc/nginx/certs/key.pem
		# config nginx with these cred
		cp /etc/nginx/sites-available/default.ssl /etc/nginx/sites-enabled/default
	fi
fi

