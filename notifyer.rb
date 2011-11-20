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
#puts h#
#  notifyer.rb
#  
#
#  Created by jules testard on 19/11/11.
#
require "redis"
require File.expand_path('./trade_manager', File.dirname(__FILE__))
require 'net/http'

#Connect to redis server
$redis= Redis.new #Redis::Scripted.connect(scripts_path: "./redis_scripts")
redis2 = Redis.new
trap(:INT) { puts; exit }

def self.find_order_ref_id(hash,redis2) 
    if hash.has_key?('parent')
      h = hash
      while h.has_key?('parent')
        h = redis2.hgetall(h['parent'])
      end
      return h['id']
      else
      return hash['id']
    end 
end

#subscribe to channel 'trade' (all incoming notifications).
h=Array.new(1000); i=0;
$redis.subscribe('trades') { |on|
  on.message {|channel,message| 
    puts "##{channel}: #{message}"
    hash = redis2.hgetall(message)
    hash['shares'] = hash['shares'].to_i
    hash['price'] = hash['price'].to_i
    buy_order = redis2.hgetall(hash['buy_order'])  
    sell_order = redis2.hgetall(hash['sell_order'])
    
    #Create parameters for sending the post to the buyer and the seller
    buy_message={}
    sell_message={}
    #message type parameter
    buy_message['MessageType']='E'
    sell_message['MessageType']='E'
    #matchNumber for the post
    buy_message['MatchNumber']=hash['id'];
    sell_message['MatchNumber']=hash['id'];
    #url to which we have to send the post
    buyer_url = buy_order['broker']
    sell_url= sell_order['broker']
    #order ref id (of parent if partial order).
    buy_message['OrderReferenceIdentifier'] = find_order_ref_id(buy_order,redis2)
    sell_message['OrderReferenceIdentifier'] = find_order_ref_id(buy_order,redis2)
    #Executed number of shares
    buy_message['ExecutedShares'] = hash['shares']
    sell_message['ExecutedShares'] = hash['shares']
    #Price of the shares
    buy_message['ExecutionPrice'] = hash['price']
    sell_message['ExecutionPrice'] = hash['price']
    #Telephone number
    buy_message['To'] = sell_order['From']
    sell_message['To'] = buy_order['From']
    
    #Send post message to 
    buy_resp = Net::HTTP.post_form(buyer_url, buy_message)
    sell_resp = Net::HTTP.post_form(sell_url, buy_message)
    
    
    #resp = Net::HTTP.post_form(buyer_url, params)
    
    puts "buy message : #{buy_message}\nsell message : #{sell_message}"
  }
  
}