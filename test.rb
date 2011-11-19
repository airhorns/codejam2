require "rubygems"
require "bundler/setup"

Bundler.require :default

$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")

class StockManager
  def initialize(name)
    @stock_name = name
  end

  def buy(from, shares, price, twilio, broker_address, broker_port, broker_url)
    $redis.fill_order([@stock_name, 'buy'], [from, shares, price, twilio, broker_address, broker_port, broker_url])
  end

  def sell(from, shares, price, twilio, broker_address, broker_port, broker_url)
    $redis.fill_order([@stock_name, 'sell'], [from, shares, price, twilio, broker_address, broker_port, broker_url])
  end
end

manager = StockManager.new("apple")
manager.buy("1234", 50, 91, true, "a", "b", "c")
manager.buy("1234", 150, 91, true, "a", "b", "c")
manager.buy("1234", 100, 92, true, "a", "b", "c")
