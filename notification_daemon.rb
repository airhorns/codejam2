require "rubygems"
require "bundler/setup"

Bundler.require :daemon

Daemons.run('notification_server.rb')
