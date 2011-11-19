require "rubygems"
require "bundler/setup"

Bundler.require :default, :web
require File.expand_path('./trade_manager', File.dirname(__FILE__))

get '/' do
  'Hello World!'
end

get '/recent_trades.json' do
  content_type :json
  TradeManager.recent_trades(10).to_json
end
