#
#  notifyer.rb
#  
#
#  Created by jules testard on 19/11/11.
#
require "redis"
require File.expand_path('./trade_manager', File.dirname(__FILE__))
#Connect to redis server

$redis= Redis.new
trap(:INT) { puts; exit }

#Create http posts for requests going 

#subscribe to channel 'trade' (all incoming notifications).
h=[]; i=0;
$redis.subscribe('trades') { |on|
  on.message {|channel,message| 
    puts "##{channel}: #{message}"
    puts TradeManager.get(message)
        #$redis.hgetall(message).tap do |hash|
        #  h[i]=hash
        #  i+=1;
      #['shares', 'price'].each { |k| hash[k] = hash[k].to_i }
        #end
        #$redis.unsubscribe('trades') if message == 'apple_trade_order_1'
  }
  
}
#puts h