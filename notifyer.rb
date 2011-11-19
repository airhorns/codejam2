#
#  notifyer.rb
#  
#
#  Created by jules testard on 19/11/11.
#
require "redis"

#Connect to redis server
redis = Redis.connect

trap(:INT) { puts; exit }

redis.subscribe(:one, :two) do |on|
  on.subscribe do |channel, subscriptions|
    puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
  end

  on.message do |channel, message|
    puts "##{channel}: #{message}"
    redis.unsubscribe if message == "exit"
  end

  on.unsubscribe do |channel, subscriptions|
    puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
  end
end