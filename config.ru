require File.expand_path './user_server', File.dirname(__FILE__)
Sinatra::Application.set :environment, :production
run Sinatra::Application
