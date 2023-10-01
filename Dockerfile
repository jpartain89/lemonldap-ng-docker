FROM debian:stable-slim
LABEL   org.opencontainers.image.authors="jpartain89" \
        name="lemonldap-ng-nginx" \
        version="v2.17.1"

ENV SSODOMAIN=example.com \
    LOGLEVEL=info \
    DEBIAN_FRONTEND=noninteractive

EXPOSE 80

RUN echo "# Install LemonLDAP::NG source repo" && \
    apt-get -y update && \
    apt-get -y install wget apt-transport-https gnupg dumb-init && \
    wget -O - https://lemonldap-ng.org/_media/rpm-gpg-key-ow2 | gpg --dearmor > /etc/apt/trusted.gpg.d/lemonldap-ng-archive-keyring.gpg \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/lemonldap-ng-archive-keyring.gpg] https://lemonldap-ng.org/deb 2.0 main" > /etc/apt/sources.list.d/lemonldap-ng.list

RUN echo "# Enable Debian backports" && \
    echo "deb http://deb.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/backports.list

RUN apt-get -y update && \
    echo "# Install LemonLDAP::NG packages" && \
    apt-get -y install nginx lemonldap-ng cron anacron liblasso-perl libio-string-perl && \
    echo "# Install LemonLDAP::NG TOTP requirements" && \
    apt-get -y install libconvert-base32-perl libdigest-hmac-perl && \
    echo "# Install LemonLDAP::NG WebAuthn requirements" && \
    apt-get -y install libauthen-webauthn-perl && \
    echo "# Install some DB drivers" && \
    apt-get -y install libdbd-mysql-perl libdbd-pg-perl && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/list/* | true

COPY docker-entrypoint.sh /

RUN echo '# Copy orignal configuration' && \
    cp -a /etc/lemonldap-ng /etc/lemonldap-ng-orig && \
    cp -a /var/lib/lemonldap-ng/conf /var/lib/lemonldap-ng/conf-orig && \
    cp -a /var/lib/lemonldap-ng/sessions /var/lib/lemonldap-ng/sessions-orig && \
    cp -a /var/lib/lemonldap-ng/psessions /var/lib/lemonldap-ng/psessions-orig

RUN echo "# Install nginx configuration files" && \
    cd /etc/nginx/sites-enabled/ && \
    ln -s ../../lemonldap-ng/handler-nginx.conf && \
    ln -s ../../lemonldap-ng/portal-nginx.conf && \
    ln -s ../../lemonldap-ng/manager-nginx.conf && \
    ln -s ../../lemonldap-ng/test-nginx.conf


RUN echo "# Configure nginx to log to standard streams" && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/etc/lemonldap-ng","/var/lib/lemonldap-ng/conf", "/var/lib/lemonldap-ng/sessions", "/var/lib/lemonldap-ng/psessions"]

ENTRYPOINT ["dumb-init","--","/bin/sh", "/docker-entrypoint.sh"]
