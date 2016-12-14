#Cmfive Developer workflow with Docker

This repository contains the DockerFile and resources to build the  [2pisoftware/cmfive docker.io image](https://hub.docker.com/r/2pisoftware/cmfive/)  which contains everything needed to install cmfive and run tests.

This document provides details on working with the image and repository.

## Getting started

- [Install docker](https://docs.docker.com/engine/installation) and Kitematic GUI
- Using Kitematic you can click `New` and search the docker hub for cmfive then click to download and run the image. 
  - This is a very large download ~400MB!! 
  - ![kitematic install cmfive](https://raw.githubusercontent.com/2pisoftware/docker-cmfive/master/doc/kitematic_install_cmfive.png)
  - Click the kitematic web preview link to access the CmFive web interface login admin/admin.
  - Read on for docker basics and how to map /var/www to your host or use the built in tools codiad and ungit and phpmyadmin to develop with the image.
  - Read the 2piSoftware quality assurance guidelines. (Code standards doc should be in wiki)

## Image Overview

The DockerFile defining the image is a combination of the phusion base image, selenium-firefox and customisations.

The image includes

- nginx, php7, mysql
- ssh access
- selenium and vncserver and firefox
- web folders for cmfive and testrunner

The image exposes the following ports 
22  ssh
80 http
443 https (not working)
3306 mysql
4444 selenium
5900 vncserver


## Docker Basics

One line restart of a cmfive container

`docker stop cmfive; docker rm cmfive; docker run --name cmfive -d -P 2pisoftware/cmfive; docker exec -it cmfive bash`

- `docker run --name <container> -d -P 2pisoftware/cmfive`  start the container with a name, auto map ports and start as daemon
- `docker exec -it <container> bash`     start an interactive bash shell inside the container
- `docker stop <container>`				 stop the container
- `docker start <container>`			 start a stopped container
- `docker rm <container>`   			 delete a container (and any changes to the filesystem)
- `docker help XXX`						


### Port Mapping
Port mapping can be controlled explicitly using -p <hostPort>:<containerPort>  

eg -p 8080:80 to map www to 8080 on host

### Other options
Other useful flags include

- --restart=no|on-failure|always|unless-stopped 
- --rm      delete container when stopped
- -- e VIRTUAL_HOST=yourdomain.com   (default cmfive.docker)   domain based mapping to containers in combination with nginx-proxy (see below)

[Docker run reference](https://docs.docker.com/engine/reference/run/)


### Cleanup

The VM is configured with a 20G drive by default. When building images and running many images the drive may fill and cause unpredictable problems. Use the following command to clean old images. 

`docker rm -v $(docker ps -a -q -f status=exited) ; docker rmi $(docker images -f "dangling=true" -q) ;  docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes`

It may also be necessary to manually remove installed images
`docker images`
`docker rmi <imageHash>`

### Volumes
                
To work directly with the container filesystem, VOLUMES can be mapped to the client. In this way platform based tools for editing and version management can be used.

`docker run --name <container> -d -P -v <hostPath>:<containerPath> 2pisoftware/cmfive`

On windows, a cygwin style path is required

eg -v //c/projects/www:/var/www

It is also possible to map a volume using kitematic.

The contents of the target container path will be replaced by the content of the host path. The contents of the volume to be mapped should be copied to the host before mapping.
`docker cp <containerName>:/var/www/ /projects/www`

To avoid problems with symbolic links, Windows users will need to run bash inside the image, zip the target folder and use docker copy and extract to the host.

### Container persistence.

Docker has images, containers and volumes.
An image is a base filesystem for a container.

A container is a running (or stopped) instance.
Containers reset their filesystem to the base image on restart.

A volume is is a storage folder that will persist between container restarts.
- Volumes are destroyed when their parent container is destroyed.
- Volumes can be defined in the build or with docker run.
- Volumes are stored in the master linux filesystem so inside virtual box for windows/mac.
- Volumes can be lost when docker engine restarts??

Where host mapping is used as described above, the content of the mount point persists no  matter what.

It is also possibly to explicitly create Data Volumes using   
  `  docker volumes create -name <volume name>  `  
This approach allows the volume to be mounted anywhere in a target image with  
   `docker run -v <volume name>`  

[Docker reference](https://docs.docker.com/engine/userguide/containers/dockervolumes/)



## Working with the image

### CmFive Web Interface


### Shell Access

You can run any command inside the image `docker exec <containerName> <command>`
You can run an interactive bash shell using `docker exec -it <containerName> bash`

### Tests

The cmfive installer `/installcmfive.sh` writes config files, runs composer updates then initialises the database and runs migrations as a one step solution for installing cmfive from source. The install script is run before each test run.

Tests can be run using the `/runtests.sh` script inside the image.
Parameters include

- testPath: filesystem path to search for tests
- testSuite: unit|acceptance
- test: individual test name  (must also provide testSuite option)
- composer:no   to disable composer update when installing cmfive

eg 
`/runTests.sh  testPath:/var/www/cmfive/system/tests testSuite:unit test:ConfigTest:testKeys`

will run a single test.


### SSH
To enable ssh, port 22 maps to a host port.
To login as root, use the key file docker.ppk from the docker-cmfive repository.

### MySql
PhpMyAdmin is available through the web interface as a top level subdirectory   
http://host:port/phpmyadmin.   
Login credentials admin/admin.  

Mysql port 3306 is exposed in the images so it is possible to map that port to a host port and use a GUI client to connect.

### Codiad IDE

 Codiad is a web based programmers editor.  
 It is available through the web interface as a top level subdirectory  `http://host:port/codiad`. Use login credentials admin/admin. 

  ![codiad](https://raw.githubusercontent.com/syntithenai/docker-cmfive/master/doc/codiad.png)

Codiad can be installed as a docker image to edit files in any container volume
    `docker run -e VIRTUAL_HOST=codiad.docker -v <\\c\host path>:/opt/codiad/workspace -v /opt/codiad/plugins trobz/codiads`

The /opt/codiad/plugins volume allows mapping of plugin folder from the host system. A collection of most codiad plugins is available as part of the docker-cmfive repository.

### GIT

Git is installed and available from the command line.

Ungit UI is available as a docker image reinblau/ungit.

[ungit](https://raw.githubusercontent.com/syntithenai/docker-cmfive/master/doc/ungit.png)
 
If you have access to the file system as a host volume mapping, you can run ungit with access to that folder 
    `docker run -e VIRTUAL_HOST=ungit.docker -v <\\c\host path>:/git reinblau/ungit`

When using the ungit UI, you search inside /git for www files.

To use ungit you must first gain shell access to the repository and to allow commit 

    git config user.name "User Name"
    git config user.email "user@2pisoftware.com" <mailto:"user@2pisoftware.com"> 
    git config core.fileMode false 

  Visit http://ungit.docker in a browser

  Enter /git/ into the search bar and look for completions.
  
 - Click enter to load the repository
 - Click plus to save the repository
 - ......

For a user guide see https://www.youtube.com/watch?v=hkBVAi3oKvo

Codiad also provides git workflows

 




##	Virtual hosting
As you add containers it can be handy to refer to them by domain name.

1. A DNS proxy will allow wildcard domain configuration (as compared to tweaking hosts entry). Acrylic DNS proxy works well on windows. 
DNS entries need to point to the virtual box IP address on windows.
2. Install and run nginx-proxy docker image using DOCKER CLI powershell. 
  `docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy`
3. Restart your container with VIRTUAL_HOST set as an environment veriable and nginx-proxy will pick up the changes and detect the container port then create virtual host entries for nginx.
  `docker run -e VIRTUAL_HOST=foo.bar.com ...`
For more details see https://hub.docker.com/r/jwilder/nginx-proxy <https://hub.docker.com/r/jwilder/nginx-proxy>





## Modifying the image
It may be appropriate to update the docker build file to make changes and rebuild the base image.  
The [docker build file](https://raw.githubusercontent.com/syntithenai/docker-cmfive/master/Dockerfile) is available as part of the docker-cmfive repository.   

Checkout and change directory to the docker-cmfive repository then run  
`docker build -t 2pisoftware/cmfive . `  

The image is based on phusion/baseimage. Detailed instructions on adding services, startup scripts and other modifications is available at [phusion.github.io](http://phusion.github.io/baseimage-docker) and [blog](https://github.com/phusion/baseimage-docker)

The image incorporates elements from the Dockerfiles for the selenium project.

The image configures a Php, nginx, mysql environment with cmfive source code.

To upload the built image to docker hub

`docker login
docker push <mylogin>/<image>
docker pull <mylogin>/<image>`



### LINKS
            <https://github.com/wsargent/docker-cheat-sheet> <https://github.com/wsargent/docker-cheat-sheet>>
            jonathan.bergknoff.com > Journal > Building-good-docker-images <http://jonathan.bergknoff.com/journal/building-good-docker-images> <http://jonathan.bergknoff.com/journal/building-good-docker-images>>
            crosbymichael.com > Dockerfile-best-practices <http://crosbymichael.com/dockerfile-best-practices.html> <http://crosbymichael.com/dockerfile-best-practices.html>>

## Docker container suite

!! THE FOLLOWING SECTION IS EXPERIMENTAL AND IN DEVELOPMENT

The repository includes composer suites to start a collection of images.
The cmfive composer suite starts containers for web, db, testrunner and selenium. 

- Checkout https://github.com/2pisoftware/docker-cmfive 
- Use bin/docker-manager.sh 
`XX/bin/docker-manager.sh up cmfive mysite
XX/bin/docker-manager.sh down cmfive mysite
` 
There are composer suites for a general webserver and a webdav server included in the repository.
`XX/bin/docker-manager.sh up webdav mydav

The manager suite also provides commands for 

- build
- killall [reallytruly] - reallytruly will stop and remove all running containers, otherwise just cleanup
- clean
- test  

In the cmfive image, the web, db and testrunner all use the cmfive base image so there is little overhead in having multiple hosts. The hosts are split to avoid a problem with circular dependancies in docker compose v1 format. v2 format offers easier network configuration but is not compatible with the proxy approach to virtual hosting described below.

All the compose suites assume that an environment variable DOCKERMANAGER_WEB_ROOT is set to a path on your local filesystem where you store websites which is volume mapped as the www or data folder for the images. 

Before using the cmfive or 2picrm images, the mapped web folder needs to be primed with a cmfive and testrunner installations.
If you run the image without composer as described in the QuickStart section above, you can copy everything you need from the container to your local file system using 
`docker cp cmfivecomplete_1:/var/www C:\Users\User\Desktop\`
OR ssh access as described below.

## Security
These images are hopelessly insecure with published default passwords for important services and a published key for root login. 

