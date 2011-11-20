require 'stock_manager'
require 'trade_manager'
require File.expand_path('./stock_manager', File.dirname(__FILE__))

class TradeManager
  def initialize(redis = nil)
    @redis = redis || $redis
  end

  def trades_since(stock, since_id = 0)
    @redis.zrangebyscore("trades_#{stock}", since_id, '+inf', :limit => [0, 2000]).map do |id|
      convert(id)
    end
  end

  def get(id)
    @redis.hgetall(id)
  end

  def convert(id)
    get(id).tap do |trade|
      ['price', 'shares'].each {|k| trade[k] = trade[k].to_i}
    end
  end

  def get_root(id)
    order = self.get(id)
    until order['parent'].nil? || order['parent'].empty?
      order = self.get(order['parent'])
    end
    order
  end

  def stocks
    $redis.smembers('stocks')
  end
end
