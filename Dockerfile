FROM amd64/ubuntu:latest

MAINTAINER Emil Moe

ARG DEBIAN_FRONTEND=noninteractive
# ENV SSHKEY

RUN echo "REPO IS:"
RUN echo REPO

WORKDIR /tmp

### Prepare packages
RUN apt-get -qq update && apt-get -qq -y upgrade
RUN apt-get install -qq -y software-properties-common python-software-properties
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/apache2
RUN apt-get -qq update

### Install dependencies
RUN apt-get -qq -y install apache2 php7.2 curl php7.2-cli php7.2-mysql php7.2-curl git gnupg php7.2-mbstring php7.2-xml unzip sudo curl php7.2-zip
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get -qq -y install nodejs 
RUN apt-get -qq -y install libtool automake autoconf nasm libpng-dev make g++

### Make SSH
RUN mkdir /root/.ssh/
RUN ssh-keyscan gitlab.com >> /root/.ssh/known_hosts
RUN echo ${SSHKEY} | base64 --decode 2> nul > /root/.ssh/id_rsa

### Configure webserver
RUN a2enmod rewrite

RUN mkdir -p /var/www/html
RUN chown www-data:www-data /var/www/html

COPY ./vhost.conf /etc/apache2/sites-enabled/001-docker.conf

### Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/sbin/composer

### Setup site
WORKDIR /var/www/html
RUN rm -f /var/www/html/*
RUN git clone ${REPO} .
RUN cp .env.production .env
RUN chown www-data:www-data .env
RUN composer -n install
RUN artisan key:generate
RUN php artisan migrate --seed

### Finishing
VOLUME ["/var/www/html"]

EXPOSE 80

ENTRYPOINT sudo /usr/sbin/apache2ctl -D FOREGROUND 
