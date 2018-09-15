## redmine3.4.3 & mysql Dockerfile
FROM centos:centos7
 
WORKDIR /usr/local/src
RUN curl -O https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz && tar xvf ruby-2.4.1.tar.gz
WORKDIR /usr/local/src/ruby-2.4.1
RUN yum update -y && \
    yum -y install which make gcc gcc-c++ patch svn git zip unzip cronie-anacron libuuid-devel xz \
                   openssl-devel readline-devel zlib-devel curl-devel libyaml-devel libffi-devel \
                   httpd httpd-devel \
                   ImageMagick ImageMagick-devel ipa-pgothic-fonts \
                   mariadb-devel && \
    ./configure --disable-install-doc && make && make install && \
    gem install bundler --no-rdoc --no-ri
 
## redmine install
RUN svn co http://svn.redmine.org/redmine/branches/3.4-stable /var/lib/redmine
COPY database.yml /var/lib/redmine/config/database.yml
COPY configuration.yml /var/lib/redmine/config/configuration.yml
COPY redmine.conf /etc/httpd/conf.d/redmine.conf
COPY welcome.conf /etc/httpd/conf.d/welcome.conf
COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY EasyGanttFree.zip /var/tmp/EasyGanttFree.zip
COPY redmine_work_time-0.3.4.zip /var/tmp/redmine_work_time-0.3.4.zip
WORKDIR /var/tmp
RUN unzip /var/tmp/EasyGanttFree.zip -d /var/lib/redmine/plugins/
RUN unzip /var/tmp/redmine_work_time-0.3.4.zip -d /var/lib/redmine/plugins/
WORKDIR /var/lib/redmine
RUN bundle install --without development test --path vendor/bundle && \
    bundle exec rake generate_secret_token
 
## passenger install
RUN gem install passenger --no-rdoc --no-ri && \
    passenger-install-apache2-module --auto && \
    chown -R apache:apache /var/lib/redmine && \
    ln -s /var/lib/redmine/public /var/www/html/redmine && \
    git clone git://github.com/farend/redmine_theme_farend_fancy.git public/themes/farend_fancy && \
    git clone https://github.com/farend/redmine_theme_farend_basic.git public/themes/farend_basic && \
    git clone https://github.com/speedy32129/time_logger.git plugins/time_logger && \
    git clone https://github.com/danmunn/redmine_dmsf plugins/redmine_dmsf && \
    git clone git://github.com/alexbevi/redmine_knowledgebase.git plugins/redmine_knowledgebase
RUN bundle install --without development test --path vendor/bundle

## settings cron
RUN echo "30 8 * * * root cd /var/lib/redmine ; rake redmine:send_reminders days=4 RAILS_ENV=production" > /var/spool/cron/root

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
 
EXPOSE 80
 
ENTRYPOINT ["/sbin/entrypoint.sh"]
