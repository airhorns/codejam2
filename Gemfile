source :rubygems
gem 'redis'
gem 'redis-scripted', :require => "redis/scripted"

group :web do
  gem 'sinatra'
  gem 'json'
  gem 'will_paginate'
  gem 'coffee-script-source', "1.1.3"
  gem 'coffee-script'
end

group :sms do
  gem "em-twilio", :git => "git://github.com/groupme/em-twilio.git"
end

group :http do
  gem 'eventmachine'
  gem "em-http-request"
  gem "hiredis", "~> 0.3.0"
  gem "em-synchrony", :require => ['em-synchrony', 'em-synchrony/em-http'], :git => "https://github.com/igrigorik/em-synchrony.git"
  gem "redis", :require => ["redis/connection/synchrony", "redis"]
end

group :server do
  gem 'goliath'
  gem 'eventmachine'
  gem "hiredis", "~> 0.3.0"
  gem "em-synchrony", :git => "https://github.com/igrigorik/em-synchrony.git"
  gem "redis", :require => ["redis/connection/synchrony", "redis"]
  gem 'redis-scripted', :require => "redis/scripted"
end

group :test do
  gem 'turn'
  gem 'minitest', '~> 2.7.0'
end

#gem 'em-redis', :git => "https://github.com/thoughtbot/em-redis.git"
