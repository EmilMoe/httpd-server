FROM amd64/debian:latest

MAINTAINER Emil Moe

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y apache2 php7.0 curl php7.0-cli php7.0-mysql php7.0-curl git curl gnupg php7.0-mbstring php7.0-xml unzip
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs

RUN adduser local --no-create-home --uid 1000 -p "" -G www-data

RUN sed -i -e 's/\var\/www\/html/\var\/www/g' /etc/apache2/apache2.conf

RUN a2enmod rewrite

RUN mkdir -p /var/www
RUN rm -r /var/www/html
RUN chown 1000:www-data www

COPY ./vhost.conf /etc/apache2/sites-enabled/001-docker.conf

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

VOLUME ["/var/www"]

RUN php artisan migrate --seed

WORKDIR /var/www

EXPOSE 80

ENTRYPOINT /usr/sbin/apache2ctl -D FOREGROUND
