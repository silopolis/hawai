# NGINX service image
FROM silopolis:lep

ARG APP_NAME="WordPress"
ARG APP_SVC_NAME="wordpress"
ARG APP_VERSION="latest"
ARG APP_ARCH_NAME="$APP_SVC_NAME-$APP_VERSION.tar.gz"
ARG APP_ARCH_URL="https://wordpress.org/$APP_ARCH_NAME"
ARG APP_ROOT_DIR="/var/www/$APP_SVC_NAME"

# OCI annotations to image
LABEL \
    org.silopolis.image.title="silopolis-$APP_NAME-$APP_VERSION" \
    org.silopolis.image.description="@silopolis' Ubuntu Focal $APP_NAME image" \
    org.silopolis.image.authors="@silopolis" \
    org.silopolis.image.source="https://github.com/silopolis/silopolis-docker" \
    org.silopolis.image.documentation="NA" \
    org.silopolis.image.base.name="docker.io/library/silopolis:$APP_NAME:$APP_VERSION" \
    org.silopolis.image.licenses="TBD" \
    org.silopolis.image.vendor="@silopolis" \
    org.silopolis.image.version="0.1" \
    org.silopolis.image.url="https://github.com/silopolis/silopolis-docker"

RUN set -eux;\
    echo "-- Downloading $APP_NAME archive."; \
    wget -q -O "$APP_ARCH_NAME" "$APP_ARCH_URL" && \
        echo "-- $APP_NAME archive successfully downloaded."; \
    echo "-- Extracting $APP_NAME archive..."; \
    tar zxf "$APP_ARCH_NAME"; \
    # echo "-- Creating app root directory: $APP_ROOT_DIR"; \
    # mkdir -p $APP_ROOT_DIR; \
    echo "-- Moving app to $APP_ROOT_DIR"; \
    mv "$APP_SVC_NAME" "$APP_ROOT_DIR"; \
    # rmdir "$APP_SVC_NAME"; \
    echo "-- Removing $APP_NAME archive"; \
    rm "$APP_ARCH_NAME"; \
    echo "-- Setting up ownership and rights"; \
    chown -R www-data:www-data "$APP_ROOT_DIR"; \
    chmod -R 755 "$APP_ROOT_DIR"

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
