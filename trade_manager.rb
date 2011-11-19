require File.expand_path('./stock_manager', File.dirname(__FILE__))

class TradeManager
  def self.recent_trades(limit)
    $redis.zrevrangebyscore('trades', '+inf', '0', {:limit => ['0', limit.to_s]}).map do |id|
      get(id)
    end
  end

  def self.get(id)
    $redis.hgetall(id).tap do |hash|
      ['shares', 'price'].each { |k| hash[k] = hash[k].to_i }
    end
  end
end
