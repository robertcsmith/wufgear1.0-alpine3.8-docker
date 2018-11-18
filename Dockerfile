FROM robertcsmith/php-cli7.2-alpine3.8-docker

LABEL robertcsmith.wufgear-tools.namespace="robertcsmith/" \
	robertcsmith.wufgear-tools.name="wufgear-tools" \
	robertcsmith.wufgear-tools.release="1.0" \
	robertcsmith.wufgear-tools.flavor="-alpine3.8" \
	robertcsmith.wufgear-tools.version="-docker" \
	robertcsmith.wufgear-tools.tag=":1.0, :latest" \
	robertcsmith.wufgear-tools.image="robertcsmith/wufgear-tools1.0-alpine3.8-docker" \
	robertcsmith.wufgear-tools.vcs-url="https://github.com/robertcsmith/wufgear-tools1.0-alpine3.8-docker" \
	robertcsmith.wufgear-tools.maintainer="Robert C Smith <robertchristophersmith@gmail.com>" \
	robertcsmith.wufgear-tools.usage="README.md" \
	robertcsmith.wufgear-tools.description="\This image provides the tools needed to properly install the source code \
for http://wufgear.com and/or make modifications to it for debugging and/or \
perform maintenance functions and/or upgrades through an interactive BASH shell. \
The container this image builds operates on a separate development source code, \
however, the connection to the database and cache containers are those used in \
production and the container is meant to be built with, and ran with only the \
tools needed and ONLY while the production container is stopped (aka down for maints) \
by the developer and the container instance should disconnect all volumes and binds, \
commit and push source code changes to git and GitHub (as well as image chaanges to \
other subtrees (aka other container images) before being destroyed. To make the changes \
within production, manually perform a git pull on the production source code. Any changes \
made to other subtrees should also be updated but assuming the changes were to the images \
The containers will need to be removed and recreated. A better document for this proceedure \
can be found in the README.md found in the same directory of this image as well as the \
directory of the Compose file which is responsible for building this app. \
See below for the needed bind mounts and volumes which must be created and paired with \
the container this image builds for proper functionality: \
    - named volume:  unix-sockets-nginx-wufgear:/var/run/php/wufgear \
    - bind-mount:    /app/src/wufgear:/var/www/wufgear \
    - bind-mount:    /app/binds/wufgear/usr-local-etc-php-fpm.d-bind:/usr/local/etc/php-fpm.d \
This image is not meant to be extended nor is it generic. It is meant for this project ONLY."

ENV WUFGEAR_VERSION="1.0" \
	# override this local variable and use the value of 'production' when deployment to production
	PHP_INI_VERSION="development" \
	# inherited PHP_INI_DIR="/usr/local/etc/php" \
	ENABLE_XDEBUG=true \
	ENABLE_SSH=true \
	ENABLE_COMPOSER=true \
	ENABLE_NODEJS=true \
	COMPOSER_VERSION=1.7.2 \
	NODE_VERSION=10.12.0 \
	YARN_VERSION=1.10.1

# Remove any inherited users or groups where there exists a possibility their
# IDs may conflit with ours and create the php user/group and nginx group are
# created correctly for this image
RUN set -x; \
	delgroup nginx && delgroup www-data 2>/dev/null; \
	addgroup -S -g 82 www-data && addgroup -S -g 101 nginx; \
	addgroup app www-data && addgroup app nginx;

RUN set -ex; \
	# Update repositories and upgrade packages then bring in the basics for tooling
    apk update && apk upgrade; \
    apk add --no-cache --virtual .fetch-deps ca-certificates curl libressl; \
    # remove any ini files to this image from our PHP_INI_DIR in favor of this specific one
    rm -rf $PHP_INI_DIR/*.in*;

COPY files/php.ini-$PHP_INI_VERSION $PHP_INI_DIR/php.ini

RUN set -ex; \
apk add --no-cache libedit-dev libedit;
apk add --no-cache php7-xdebug; \
echo "[xdebug]" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.idekey = PHPSTORM" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.remote_autostart = 1" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.remote_connect_back = 0" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.remote_enable = 1" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.remote_host = 10.254.254.254" >> ${PHP_INI_DIR}/php.ini \
&& echo "xbebug.remote_connect_back = 1" >> ${PHP_INI_DIR}/php.ini \
&& echo "xdebug.remote_port = 9001" >> ${PHP_INI_DIR}/php.ini; \
# or should I do cat /etc/php7/conf.d/xdebug.ini >> ${PHP_INI_DIR}/php.ini; the pregex

# ----- COMPOSER (PHP)-----
COPY --from=composer:1.7.2 /usr/bin/composer /usr/local/bin/composer

# ----- NODEJS -----
COPY --from=node:11.0.0-alpine /usr/local/bin/node /usr/local/bin/node
COPY --from=node:11.0.0-alpine /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node:11.0.0-alpine /usr/local/bin/yarn /usr/local/bin/yarn
COPY --from=node:11.0.0-alpine /usr/local/bin/yarnpkg /usr/local/bin/yarnpkg
RUN set -ex; \
	addgroup S -g 1982 node; \
	addgroup app node; \
	mkdir -p /var/www/wufgear/.config /var/www/wufgear/.npm 2>/dev/null;\
    chown -R app:node /var/www/wufgear/.config/ /var/www/wufgear/.npm/ \
    ln -s /var/www/wufgear/node_modules/grunt/bin/grunt /usr/bin/grunt; \
	fi;

RUN chown -R www-data:nginx /var/run/php/ &&  exec $REMOVE_BASE_PKGS
EXPOSE 9001
COPY files/entrypoint.sh  /usr/local/bin/docker-entrypoint
ENTRYPOINT [ "docker-entrypoint" ]
CMD [ "bash" ]
