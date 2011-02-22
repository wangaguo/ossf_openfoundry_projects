# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ROOT_PATH = OpenFoundry::Application.config.root_path 
OpenFoundry::Application.initialize!
