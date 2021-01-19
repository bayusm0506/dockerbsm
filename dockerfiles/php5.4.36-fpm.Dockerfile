FROM php:5.4.36-fpm

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libicu-dev \
    libmysqlclient18 \
    libc6 \
    libaio1 \
    zlib1g \
    make \
    php5-dev \
    php-pear \
    libcurl4-gnutls-dev \
    unzip \
    libcurl4-gnutls-dev \
    libxml2-dev

RUN docker-php-ext-install intl pdo_mysql mbstring sockets soap calendar 

RUN mkdir /opt/oracle \
    && unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle/ \
    && unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle/ \
    && ln -s /opt/oracle/instantclient_12_1 /opt/oracle/instantclient \
    && ln -s /opt/oracle/instantclient/libclntsh.so.12.1 /opt/oracle/instantclient/libclntsh.so \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient \
    && docker-php-ext-install oci8

ADD php.ini $PHP_INI_DIR/conf.d/php.ini

# RUN rm -rf /tmp/* \
#     && echo "=============================================" \
#     && php -m