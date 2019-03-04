FROM php:5.6-fpm

MAINTAINER Jimbo <jimmy@showpo.com>
# Thanks to Johan van Helden <johan@johanvanhelden.com> for the original - I just added more stuff!!!

# Set environment variables
ARG TZ=Australia/Sydney
ENV TZ ${TZ}

# Install dependencies
RUN apt-get update && apt-get install -y \
    mysql-client \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libcurl4-nss-dev \
    libc-client-dev \
    libkrb5-dev \
    firebird-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    ssmtp \
    libssh2-1-dev \
    git \
    python \
    python-pip \
    curl \
    wget \
    mysql-client \
    libyaml-dev \
    python-dev \
    gnupg \
    unzip

RUN docker-php-ext-install -j$(nproc) mcrypt \
    && docker-php-ext-install -j$(nproc) curl \
    && docker-php-ext-install -j$(nproc) mbstring \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-install -j$(nproc) interbase \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) soap \
    && docker-php-ext-install -j$(nproc) xmlrpc \
    && docker-php-ext-install -j$(nproc) xsl \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-install mysql mysqli pdo pdo_mysql \
    && docker-php-ext-install zip

# redis module
RUN \
  pecl install -o -f redis \
  &&  echo "extension=redis.so" > /usr/local/etc/php/conf.d/ext-redis.ini

# ssh2 module
RUN \
  pecl install ssh2 \
  && echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ext-ssh2.ini

# Install cron
RUN apt-get update && apt-get install -y \
        cron

# Set the timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install the xdebug extension
RUN pecl install xdebug-2.5.5 && \
    docker-php-ext-enable xdebug

# Copy xdebug configration for remote debugging
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Copy the php-fpm config
COPY ./dockerhero.fpm.conf /usr/local/etc/php-fpm.d/zzz-dockerhero.fpm.conf
COPY ./dockerhero.php.ini /usr/local/etc/php/conf.d/dockerhero.php.ini

# Download the latest version of magerun
RUN curl https://files.magerun.net/n98-magerun.phar -o /n98-magerun.phar
RUN chmod +x /n98-magerun.phar
RUN mv /n98-magerun.phar /usr/local/bin/

# Install PHPUnit
RUN cd /tmp && curl -L https://phar.phpunit.de/phpunit-5.7.phar > phpunit.phar && \
    chmod +x phpunit.phar && \
    mv /tmp/phpunit.phar /usr/local/bin/phpunit
    
# Install Composer globally
RUN curl --silent --show-error https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
    
# Install AWS CLI    
RUN pip install awscli

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
  apt-get install -y nodejs
  
# Install jslint via npm
RUN npm install -g jshint

# Cleanup all downloaded packages
RUN apt-get -y autoclean && apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/* && apt-get update

# Set the proper permissions
RUN usermod -u 1000 www-data

# Add the startup script and set executable
COPY ./.startup.sh /var/scripts/.startup.sh
RUN chmod +x /var/scripts/.startup.sh

# Run the startup script
CMD ["/var/scripts/.startup.sh"]
