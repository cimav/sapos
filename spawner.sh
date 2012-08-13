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

export GOOGLE_KEY='435428651303.apps.googleusercontent.com'
export GOOGLE_SECRET='d_tFDnNLT7sA-C33sI-WpN8q'
export RAILS_ENV='production'

unicorn -p 3000
