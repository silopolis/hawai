# NGINX service image
FROM silopolis:nginx

ARG PHP_VERSION=7.4

# OCI annotations to image
LABEL \
    org.silopolis.image.title="silopolis-php-$PHP_VERSION" \
    org.silopolis.image.description="@silopolis' Ubuntu Focal NGINX/PHP-FPM $PHP_VERSION image" \
    org.silopolis.image.authors="@silopolis" \
    org.silopolis.image.source="https://github.com/silopolis/silopolis-docker" \
    org.silopolis.image.documentation="NA" \
    org.silopolis.image.base.name="docker.io/library/silopolis:php:$PHP_VERSION" \
    org.silopolis.image.licenses="TBD" \
    org.silopolis.image.vendor="@silopolis" \
    org.silopolis.image.version="0.1" \
    org.silopolis.image.url="https://github.com/silopolis/silopolis-docker"

#SHELL ["/bin/bash", "-o"]
#ENV PHP_VERSION=$PHP_VERSION
ENV DEBIAN_FRONTEND noninteractive

# Use deb.sury.org PHP packages
RUN set -eux; \
    php="php$PHP_VERSION"; \
    add-apt-repository ppa:ondrej/php; \
    apt-get update; \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install --no-install-recommends \
        $php $php-common php-pear $php-cli $php-fpm $php-curl $php-gd \
        $php-mbstring $php-xml $php-zip $php-xmlrpc php-imagick \
        $php-mysql mariadb-client; \
    #    $php-pgsql postgresql-client; \
    apt-get -qq clean; \
    #apt-get -qq purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get -qq -y autoremove; \
    apt-get -qq -y autoclean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# TODO PHP config

RUN systemctl enable nginx.service;

ENV DEBIAN_FRONTEND dialog

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
