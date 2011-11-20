require "rubygems"
require "bundler/setup"
require 'net/http'
require 'uri'

Bundler.require :default, :sms

$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")
subscriber = Redis.new

$: << "."
require 'trade_manager'

trap(:INT) { puts; exit }

# put your own credentials here
account_sid = "AC888a285988894223a40b8d0df20d6d58"
auth_token = "6ea425d908a216d20d505eb013d55985"
number = "+15148005440"

# set up a client to talk to the Twilio REST API
@client = Twilio::REST::Client.new account_sid, auth_token

def notify_via_sms(order, trade)
  puts "Notifying #{order['from']}", @client.account.sms.messages.create(
    :from => number,
    :to => order['from'],
    :body => sms_body(order, trade)
  )
end

def sms_body(order, trade)
  "Your order #{order['id']} has been executed for #{trade['shares']} shares. Your match # is #{trade['id']} and the trade executed at #{trade['price'].to_f / 100} per share."
end

subscriber.subscribe('trades') do |on|
  on.message do |channel, message|
    trade = TradeManager.get(message)
    buy_order = TradeManager.get_root(trade['buy_order'])
    sell_order = TradeManager.get_root(trade['sell_order'])

    puts "*******"
    puts buy_order
    puts sell_order

    [buy_order, sell_order].each do |order|
      notify_via_sms(order, trade) if order['twilio'] == 'true'
    end
  end
end
