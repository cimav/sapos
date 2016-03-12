# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sapos::Application.initialize!

# Set config custom variables
Sapos::Application.config.admin_email=""
