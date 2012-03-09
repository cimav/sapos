# Config
GAPPS_DOMAIN = 'cimav.edu.mx'
GAPPS_CONSUMER_KEY = GAPPS_DOMAIN
GAPPS_CONSUMER_SECRET = '7rnMDVitfQiVgcBYQyBu7oku'
GAPPS_REQUESTOR_ID = 'ion@cimav.edu.mx'

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sapos::Application.initialize!

