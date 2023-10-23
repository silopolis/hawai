# NGINX service image
FROM silopolis:base

# OCI annotations to image
LABEL \
    org.silopolis.image.title="silopolis-nginx" \
    org.silopolis.image.description="@silopolis' Ubuntu Focal NGINX image" \
    org.silopolis.image.authors="@silopolis" \
    org.silopolis.image.source="https://github.com/silopolis/silopolis-docker" \
    org.silopolis.image.documentation="NA" \
    org.silopolis.image.base.name="docker.io/library/silopolis:nginx" \
    org.silopolis.image.licenses="TBD" \
    org.silopolis.image.vendor="@silopolis" \
    org.silopolis.image.version="0.1" \
    org.silopolis.image.url="https://github.com/silopolis/silopolis-docker"

#SHELL ["/bin/bash", "-o"]
ENV DEBIAN_FRONTEND noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install --no-install-recommends \
        nginx-extras; \
    apt-get -qq clean; \
    #apt-get -qq purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get -qq -y autoremove; \
    apt-get -qq -y autoclean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN systemctl enable nginx.service;

RUN pipx install --include-deps certbot==2.7.2; \
    pipx inject --include-deps --include-apps certbot certbot-dns-multi==4.14.2; \
    pipx inject --include-deps --include-apps certbot certbot-nginx==2.7.2

ENV DEBIAN_FRONTEND dialog

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
