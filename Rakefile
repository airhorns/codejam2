require 'rake/testtask'
require 'rubygems'
require 'bundler/setup'
Bundler.require :default
$: << '.'

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
