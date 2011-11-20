require 'stock_manager'
require 'trade_manager'
require File.expand_path('./stock_manager', File.dirname(__FILE__))

class TradeManager
  def initialize(redis = nil)
    @redis = redis || $redis
  end

  def recent_trades(limit)
    @redis.zrevrangebyscore('trades', '+inf', '0', {:limit => ['0', limit.to_s]}).map do |id|
      get(id)
    end
  end

  def get(id)
    @redis.hgetall(id)
  end

  def get_root(id)
    order = self.get(id)
    until order['parent'].nil? || order['parent'].empty?
      order = self.get(order['parent'])
    end
    order
  end
end
