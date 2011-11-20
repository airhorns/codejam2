require 'rake/testtask'
require 'rubygems'
require 'bundler/setup'
Bundler.require :default
$: << '.' << './lib'

Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb"
end

desc 'reset the database'
task :reset => :redis do
  require 'stock_manager'
  StockManager.new("").reset!
end

desc 'spin up redis'
task :redis do
  $redis = Redis.new
end

desc 'get sha'
task :sha do
  require "digest/sha1"
  puts Digest::SHA1.hexdigest(File.read('./redis_scripts/fill_order.lua'))
end
