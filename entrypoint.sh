#!/bin/bash
 
/usr/sbin/crond
cd /var/lib/redmine
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:plugins
RAILS_ENV=production REDMINE_LANG=ja bundle exec rake redmine:load_default_data
/usr/sbin/httpd -D FOREGROUND
