# MariaDB service image
FROM silopolis:base

# OCI annotations to image
LABEL \
    org.silopolis.image.title="silopolis-mariadb" \
    org.silopolis.image.description="@silopolis' Ubuntu Focal MariaDB image" \
    org.silopolis.image.authors="@silopolis" \
    org.silopolis.image.source="https://github.com/silopolis/silopolis-docker" \
    org.silopolis.image.documentation="NA" \
    org.silopolis.image.base.name="docker.io/library/silopolis:mariadb" \
    org.silopolis.image.licenses="TBD" \
    org.silopolis.image.vendor="@silopolis" \
    org.silopolis.image.version="0.1" \
    org.silopolis.image.url="https://github.com/silopolis/silopolis-docker"

#SHELL ["/bin/bash", "-o"]
ENV DEBIAN_FRONTEND noninteractive

#ARG DBA_PASSWORD
# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN groupadd -r mysql && useradd -r -g mysql mysql

# TODO Use backport or upstream package, or upstream container
RUN set -eux; \
    { \
        echo "mariadb-server" mysql-server/data-dir select ''; \
        echo "mariadb-server" mysql-server/root_password password 'unused'; \
        echo "mariadb-server" mysql-server/root_password_again password 'unused'; \
        echo "mariadb-server" mysql-server/remove-test-db select false; \
	} | debconf-set-selections; \
    # Postinst script creates a datadir, so avoid creating it by faking its existance.
	mkdir -p /var/lib/mysql/mysql; touch /var/lib/mysql/mysql/user.frm; \
    apt-get update; \
    #apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install \
        libjemalloc2 pwgen tzdata xz-utils zstd socat \
        mariadb-server mariadb-client mariadb-backup; \
	#rm -rf /etc/mysql/mariadb.conf.d/50-mariadb_safe.cnf; \
    # Purge and re-create /var/lib/mysql with appropriate ownership
    rm -vrf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld; \
	chown -vR mysql:mysql /var/lib/mysql /var/run/mysqld; \
    # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	chmod -v 1777 /var/run/mysqld; \
    # comment out a few problematic configuration values
	# find /etc/mysql/ -name '*.cnf' -print0 \
	# 	| xargs -0 grep -lZE '^(bind-address|log|user\s)' \
	# 	| xargs -rt -0 sed -Ei 's/^(bind-address|log|user\s)/#&/'; \
    # don't reverse lookup hostnames, they are usually another container
	printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" > /etc/mysql/mariadb.conf.d/05-skipcache.cnf; \
    # Issue #327 Correct order of reading directories /etc/mysql/mariadb.conf.d before /etc/mysql/conf.d (mount-point per documentation)
	# if [ -L /etc/mysql/my.cnf ]; then \
    #     # 10.5+
	# 	sed -i -e '/includedir/ {N;s/\(.*\)\n\(.*\)/\n\2\n\1/}' /etc/mysql/mariadb.cnf; \
	# fi
    apt-get -qq clean; \
    #apt-get -qq purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get -qq -y autoremove; \
    apt-get -qq autoclean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN systemctl enable mariadb.service;

#COPY --chmod=700 mariadb-secure-install.sh /
#RUN /mariadb-secure-install.sh $DBA_PASSWORD && \
#    rm /mariadb-secure-install.sh

ENV DEBIAN_FRONTEND dialog

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
