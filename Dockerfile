FROM amd64/ubuntu:latest

MAINTAINER Emil Moe

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

# RUN apt-get update
# RUN apt-get upgrade -y
RUN apt-get -qq update
RUN apt-get -qq -y upgrade

RUN apt-get -qq -y install apache2 php7.2 curl php7.2-cli php7.2-mysql php7.2-mcrypt php7.2-curl git gnupg php7.2-mbstring php7.2-xml unzip sudo curl php7.2-zip
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get -qq -y install nodejs 

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

EXPOSE 80 9515

ENTRYPOINT sudo /usr/sbin/apache2ctl -D FOREGROUND 
