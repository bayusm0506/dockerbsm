FROM php:5.6.30-fpm-alpine

RUN apk add --no-cache --virtual .build-deps \
    # for all
    zlib-dev \
    # dev deps for gd
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    # for intl
    icu-dev \
    # for mcrypt
    libmcrypt-dev \
    # for soap
    libxml2-dev \
    # for xsl
    libxslt-dev \
    # for ldap
    openldap-dev \
    # to build xdebug from PECL
    $PHPIZE_DEPS \
    # && pecl install xdebug \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install \
    bcmath \
    gd \
    intl \
    ldap \
    mbstring \
    mcrypt \
    mysqli \
    opcache \
    pdo_mysql \
    soap \
    xsl \
    zip \
    # next will add runtime deps for php extensions
    # what this does is checks the necessary packages for php extensions Shared Objects
    # and adds those (won't be removed when .build-deps are)
    && runDeps="$( \
    scanelf --needed --nobanner --recursive \
    /usr/local/lib/php/extensions \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u \
    | xargs -r apk info --installed \
    | sort -u \
    )" \
    && apk add --virtual .phpexts-rundeps $runDeps \
    && apk del .build-deps

# modify www-data user to have id 1000
RUN apk add \
    --no-cache \
    --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted \
    --virtual .shadow-deps \
    shadow \
    && usermod -u 1000 www-data \
    && groupmod -g 1000 www-data \
    && apk del .shadow-deps \
    # Install composer
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "copy('https://composer.github.io/installer.sig', 'signature');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === trim(file_get_contents('signature'))) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

RUN mkdir /opt \
    && mkdir /opt/oracle \
    && unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle/ \
    && unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle/ \
    && ln -s /opt/oracle/instantclient_12_1 /opt/oracle/instantclient \
    && ln -s /opt/oracle/instantclient/libclntsh.so.12.1 /opt/oracle/instantclient/libclntsh.so \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient \
    && docker-php-ext-install oci8

ADD php.ini $PHP_INI_DIR/conf.d/php.ini

# COPY docker-php-entrypoint /usr/local/bin/

# VOLUME /srv/www
# WORKDIR /srv/www

# CMD ["php-fpm"]