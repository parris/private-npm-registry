FROM ubuntu

RUN apt-get update -y
RUN apt-get install -y vim git-core build-essential g++ libssl-dev curl wget apache2-utils libxml2-dev libpcre3 libpcre3-dev

RUN mkdir download

# Download nginx
WORKDIR /download
RUN wget http://nginx.org/download/nginx-1.2.6.tar.gz
RUN tar xvzf nginx-1.2.6.tar.gz
WORKDIR /download/nginx-1.2.6

# Install nginx
RUN ./configure --prefix=/opt/nginx --user=nginx --group=nginx --with-http_sub_module --with-http_ssl_module --without-http_scgi_module --without-http_uwsgi_module --without-http_fastcgi_module
RUN make && make install
ADD nginx/upstart.conf /etc/init/nginx.conf
ADD nginx/nginx.conf /opt/nginx/conf/nginx.conf
ADD nginx/cache_zone.conf /opt/nginx/conf/conf.d/npm_proxy.conf
ADD nginx/server.conf /opt/nginx/conf/sites-enabled/npm_proxy.conf
RUN sudo service nginx start

# Install NVM
WORKDIR /download
RUN curl https://raw.github.com/creationix/nvm/master/install.sh | sh
RUN echo '. /.nvm/nvm.sh' >> /etc/bash.bashrc
RUN /bin/bash -c '. /.nvm/nvm.sh; nvm install v0.10.26; nvm use v0.10.20'

# Setup Kappa and Start
RUN mkdir /opt/kappa
WORKDIR /opt/kappa
ADD kappa/upstart.conf /etc/init/kappa.conf
ADD kappa/config.json /opt/kappa/config.json
ADD kappa/package.json /opt/kappa/package.json
RUN npm install
RUN npm start

# Setup Reggie and Start
RUN mkdir /opt/kappa
RUN npm install reggie
ADD reggie/upstart.conf /etc/init/reggie.conf
RUN ./node_modules/.bin/reggie-server
