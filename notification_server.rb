require "rubygems"
require "bundler/setup"
require 'net/http'
require 'uri'

$: << "." << './lib'
Bundler.require :http, :sms

require "em-synchrony/fiber_iterator"

EventMachine.synchrony do
  $redis = Redis.new
  $subscriber = Redis.new

  require 'trade_manager'
  require 'notifications'

  manager = EventMachine::Synchrony::ConnectionPool.new(size: 5) do
    redis = Redis.new
    TradeManager.new(redis)
  end

  $subscriber.subscribe 'trades' do |on|

    on.subscribe do |channel|
      puts "Listening for messages on ##{channel}."
    end

    on.message do |channel, message|
      Fiber.new do
        trade = manager.get(message)
        EM::Synchrony::FiberIterator.new(['buy_order', 'sell_order'], 2).each do |key|
          order = manager.get_root(trade[key])
          Notifications::notify_via_http(order, trade)
          Notifications::notify_via_sms(order, trade) if order['twilio'] == 'true'
        end
      end.resume
    end
  end
end
