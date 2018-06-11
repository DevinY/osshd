FROM alpine
MAINTAINER Devin Yang <devin@ccc.tc> 

ARG key

ENV KEY ${key:-nokey}

ARG user

ENV OSSH_USER ${user:-git}

RUN apk update&&apk add openssh git pwgen rsync


RUN mkdir /var/run/sshd
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN mkdir /root/.ssh

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa &&\  
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa &&\
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa &&\
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519

RUN adduser -D -s /bin/sh -h /home/${OSSH_USER} ${OSSH_USER};echo "${OSSH_USER}:`pwgen`" |chpasswd > /dev/null 2>&1

USER ${OSSH_USER}

RUN mkdir -p /home/${OSSH_USER}/.ssh&&chmod 700 /home/${OSSH_USER}/.ssh

RUN echo "${KEY}" > /home/${OSSH_USER}/.ssh/authorized_keys

RUN chmod 600 /home/${OSSH_USER}/.ssh/authorized_keys

USER root

RUN apk del pwgen

#===========編譯PHP========
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F 

ENV PHP_VERSION 7.2.6
ENV PHP_URL="https://secure.php.net/get/php-7.2.6.tar.xz/from/this/mirror" PHP_ASC_URL="https://secure.php.net/get/php-7.2.6.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="1f004e049788a3effc89ef417f06a6cf704c95ae2a718b2175185f2983381ae7" PHP_MD5=""
# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev \
    pcre-dev \
    pcre2-dev \
    libintl \
    gettext-dev \
    file \
    g++ \
    gcc \
    libc-dev \
    libpcre32 \
    make \
    re2c

RUN apk update && apk add \
    $PHPIZE_DEPS \
    ca-certificates \
    dpkg \
    curl \
    sqlite-dev \
    libxml2 \
    xz-dev \
    sudo \
    git \
    wget \
    python \
    vim \
    unzip \
    mysql-client \
    zip \
    bzip2-dev \
    gd-dev \
    libpng-dev \
    jpeg-dev \
    giflib-dev \
    supervisor 

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d


RUN set -xe; \
\
fetchDeps=''; \
if ! command -v gpg > /dev/null; then \
fetchDeps="$fetchDeps \
gnupg \
"; \
fi; \
apk update; \
apk add --no-cache $fetchDeps; \
\
mkdir -p /usr/src; \
cd /usr/src; \
\
wget -O php.tar.xz "$PHP_URL"; \
\
if [ -n "$PHP_SHA256" ]; then \
echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
fi; \
if [ -n "$PHP_MD5" ]; then \
echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
fi; \
\
if [ -n "$PHP_ASC_URL" ]; then \
wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
export GNUPGHOME="$(mktemp -d)"; \
for key in $GPG_KEYS; do \
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
done; \
gpg --batch --verify php.tar.xz.asc php.tar.xz; \
rm -rf "$GNUPGHOME"; \
fi  


COPY docker-php-source /usr/local/bin/

RUN set -xe \
&& buildDeps=" \
$PHP_EXTRA_BUILD_DEPS \
curl-dev \
libedit-dev \
sqlite-dev \
openssl-dev \
libxml2-dev \
zlib-dev \
" \
&& apk update && apk add $buildDeps && rm -rf /var/lib/apt/lists/* \
&& export CFLAGS="$PHP_CFLAGS" \
CPPFLAGS="$PHP_CPPFLAGS" \
LDFLAGS="$PHP_LDFLAGS" \
&& docker-php-source extract \
&& cd /usr/src/php \
&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
# https://bugs.php.net/bug.php?id=74125
&& if [ ! -d /usr/include/curl ]; then \
ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
fi \
&& ./configure \
--build="$gnuArch" \
--with-config-file-path="$PHP_INI_DIR" \
--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
--disable-cgi \
\
--enable-ftp \
--enable-mbstring \
--enable-zip \
--enable-opcache-file \
--with-bz2 \
--with-gettext \
--enable-sockets \
--enable-pcntl \
--enable-phpdbg-debug \
--enable-debug \
--enable-mysqlnd \
--enable-exif \
--enable-sqlite-utf8 \
--enable-zip \
--enable-pcntl \
\
--with-curl \
--with-libedit \
--with-openssl \
--with-zlib \
--with-mysqli \
--with-pdo-mysql \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-gif-dir \
\
--with-pcre \
--with-libdir="lib/$debMultiarch" \
\
$PHP_EXTRA_CONFIGURE_ARGS \
&& make -j "$(nproc)" \
&& make install \
&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
&& make clean \
&& cd / \
&& docker-php-source delete \
&& pecl update-channels \
&& rm -rf /tmp/pear ~/.pearrc
#===========================
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
                       ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');"); \
                       php composer-setup.php; \
                       php -r "unlink('composer-setup.php');"; \
                       mv composer.phar /usr/local/bin/composer; \
                       echo 'export TERM=xterm-256color' >> /root/.bashrc; \
                       echo 'export PATH=/root/.composer/vendor/bin:$PATH' >> /root/.bashrc;

EXPOSE 22

CMD  ["/usr/sbin/sshd", "-D"]
