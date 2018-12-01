FROM ubuntu:latest

# Update Timezone
ENV TZ Asia/Hong_Kong
RUN echo $TZ > /etc/timezone

# Use Local Mirror hk.archive.ubuntu.com 
RUN sed -i -e "s/archive/hk\.archive/" /etc/apt/sources.list

#add repository and update the container
#Installation of nesesary package/software for this containers...
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y -q php \
                    libapache2-mod-php \
                    php-gd \
                    apache2 \
                    php-mysql \
                    php-json \
                    php-curl \
                    php-intl \
                    php-sqlite3 \
                    php-mbstring \
                    unzip \
				#	wkhtmltox \
                    && apt-get clean \
                    && rm -rf /tmp/* /var/tmp/*  \
                    && rm -rf /var/lib/apt/lists/*

# Add apache config to enable .htaccess and do some stuff you want
COPY apache_default /etc/apache2/sites-available/000-default.conf

# Enable mod rewrite and listen to localhost
RUN a2enmod rewrite && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf

################################################################
# Example, deploy a default CakePHP 3 installation from source #
################################################################

# Clone your application (cloning CakePHP 3 / app instead of composer create project to demonstrate application deployment example)
RUN rm -rf /var/www/html && \
	git clone https://github.com/cakephp/app.git /var/www/html

# Set workdir (no more cd from now)
WORKDIR /var/www/html

# Composer install application
RUN composer -n install

# Copy the app.php file
RUN cp config/app.default.php config/app.php && \
	# Inject some non random salt for this example 
	sed -i -e "s/__SALT__/somerandomsalt/" config/app.php && \
	# Make sessionhandler configurable via environment
	sed -i -e "s/'php',/env('SESSION_DEFAULTS', 'php'),/" config/app.php  && \
	# Set write permissions for webserver
	chgrp -R www-data logs tmp && \
	chmod -R g+rw logs tmp 

####################################################
# Expose port and run Apache webserver             #
####################################################

EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]
