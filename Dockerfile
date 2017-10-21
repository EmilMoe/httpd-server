FROM amd64/debian:latest

MAINTAINER Emil Moe

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /tmp

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y apache2 php7.0 curl php7.0-cli php7.0-mysql php7.0-curl git gnupg php7.0-mbstring php7.0-xml unzip sudo curl
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs 

RUN adduser local --disabled-password

RUN echo "local ALL = NOPASSWD: ALL" >> /etc/sudoers

RUN a2enmod rewrite

RUN mkdir -p /var/www/html
RUN rm /var/www/html/index.html
RUN chown local:www-data /var/www/html

COPY ./vhost.conf /etc/apache2/sites-enabled/001-docker.conf

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

VOLUME ["/var/www/html"]

WORKDIR /var/www/html

RUN su local && composer -n install
RUN su local -c npm install --no-optional
RUN su local -c php artisan migrate --seed

EXPOSE 80

ENTRYPOINT sudo /usr/sbin/apache2ctl -D FOREGROUND 
