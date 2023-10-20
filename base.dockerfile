## Base image
FROM ubuntu:focal

# OCI annotations to image
LABEL \
    org.silopolis.image.title="silopolis-focal-base" \
    org.silopolis.image.description="@silopolis' Ubuntu Focal base image" \
    org.silopolis.image.authors="@silopolis" \
    org.silopolis.image.source="https://github.com/silopolis/silopolis-docker" \
    org.silopolis.image.documentation="NA" \
    org.silopolis.image.base.name="docker.io/library/silopolis:focal" \
    org.silopolis.image.licenses="TBD" \
    org.silopolis.image.vendor="@silopolis" \
    org.silopolis.image.version="0.1" \
    org.silopolis.image.url="https://github.com/silopolis/silopolis-docker"

#SHELL ["/bin/bash", "-o"]
ENV DEBIAN_FRONTEND noninteractive
#ENV RUNLEVEL 1

# FIXME systemd setup: ln: failed to create symbolic link '/etc/resolv.conf': Device or resource busy
RUN set -eux; \
    apt-get update; \
    apt-get -qq -y upgrade; \
    echo "resolvconf resolvconf/linkify-resolvconf boolean false" \
        | debconf-set-selections; \
    #apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install \
        apt-utils debconf-utils systemd;

# FXIME openssh-server setup: invoke-rc.d: policy-rc.d denied execution of start.
RUN set -eux; \
    #apt-get -qq -y -o=Dpkg::Use-Pty=0 --no-install-recommends install \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install \
        openssh-server passwd sudo iproute2 git curl iputils-ping net-tools \
        wget curl systemd whois ca-certificates lsof;

RUN set -eux; \
    apt-get -qq -y -o=Dpkg::Use-Pty=0 install python3-pip; \
    pip install j2cli;

WORKDIR /lib/systemd/system/sysinit.target.wants/
RUN  set -ux; \
    (for i in ./*; do \
        [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; \
     done \
    ); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    systemctl disable --now systemd-resolved.service; \
    systemctl enable ssh.service;

WORKDIR /

# FIXME chpasswd: (user -e vagrant) pam_chauthtok() failed, error: admin: Authentication token manipulation error
#       chpasswd: (line 1, user -e vagrant) password not changed
#       See https://stackoverflow.com/questions/66190675/docker-set-user-password-non-interactively
#           https://github.com/sequenceiq/docker-pam
RUN set -eux; \
    useradd --create-home -s /bin/bash -p `mkpasswd --method=SHA-512 vagrant` vagrant; \
    echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant; \
    chmod 440 /etc/sudoers.d/vagrant; \
    mkdir -p /home/vagrant/.ssh; \
    chmod 700 /home/vagrant/.ssh; \
    curl --silent --output /home/vagrant/.ssh/authorized_keys \
      https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub; \
    chmod 600 /home/vagrant/.ssh/authorized_keys; \
    chown -R vagrant:vagrant /home/vagrant/.ssh

RUN set -eux; \
    apt-get -qq -y clean; \
    #apt-get -qq purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get -qq -y autoremove; \
    apt-get -qq -y autoclean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV DEBIAN_FRONTEND dialog

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
