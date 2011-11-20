source :rubygems
gem 'redis'
gem 'redis-scripted', :require => "redis/scripted"

group :web do
  gem 'sinatra'
  gem 'json'
  gem 'will_paginate'
end

group :server do
  gem 'goliath'
  gem 'eventmachine' #, :git => "https://github.com/eventmachine/eventmachine.git"
  gem "hiredis"
  gem "em-synchrony" #, :git => "https://github.com/igrigorik/em-synchrony.git"
  gem "redis", :require => ["redis/connection/synchrony", "redis"]
  gem 'redis-scripted', :require => "redis/scripted"
end

group :test do
  gem 'turn'
  gem 'minitest', '~> 2.7.0'
end

#gem 'em-redis', :git => "https://github.com/thoughtbot/em-redis.git"
