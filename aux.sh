#!/bin/bash

if [ "$(whoami)" != "rails" ]; then
echo "Cannot run this script as root. You must sudo to the 'rails' user."
exit -1;
fi

export HOME="/home/rails"

if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
source "$HOME/.rvm/scripts/rvm";
fi

cd /home/rails/sapos

#gem install bundler
#bundler install
#rvm list
#gem install rails -v 3.2.14
#bundle install 
#gem install unicorn
#bundle install
#rake db:migrate   RAILS_ENV="production"
#rake assets:clean   RAILS_ENV="production"
rake assets:precompile   RAILS_ENV="production"
#rake payments:check  RAILS_ENV="production"
#rake admin:protocols RAILS_ENV="production"
#rake grades:alarm RAILS_ENV="production"
#rake grades:check RAILS_ENV="production"
#rake payments:check  RAILS_ENV="production"

