require "rubygems"
require "bundler/setup"

Bundler.require :default

$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")

class StockManager
  def self.get(id)
    $redis.hgetall(id)
  end

  def initialize(name)
    @stock_name = name
  end

  def buy(from, shares, price, twilio, broker)
    $redis.fill_order([@stock_name, 'buy'], [from, shares, price, twilio, broker, timestamp])
  end

  def sell(from, shares, price, twilio, broker)
    $redis.fill_order([@stock_name, 'sell'], [from, shares, price, twilio, broker, timestamp])
  end

  def reset!
    $redis.keys("*").each do |key|
      $redis.del(key)
    end
  end

  def outstanding_buy_orders
    $redis.zcard("#{@stock_name}_buy_orders")
  end

  def outstanding_sell_orders
    $redis.zcard("#{@stock_name}_sell_orders")
  end

  def get(id)
    $redis.hgetall(id)
  end

  def get_order(type, id)
    $redis.hgetall("#{@stock_name}_#{type}_#{id}")
  end

  def filled?(id)
    $redis.hget(id, 'filled') == '1'
  end

  def trade_count
    $redis.zcard('trades')
  end

  private

  def timestamp
    Time.now.strftime("%Y-%m-%dT%H:%M:%S.%1N")
  end
end
