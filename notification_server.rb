require "rubygems"
require "bundler/setup"
require 'net/http'
require 'uri'

$: << "."
Bundler.require :http
require "em-synchrony/fiber_iterator"

EventMachine.synchrony do
  $redis = Redis.new
  $subscriber = Redis.new

  require 'trade_manager'

  def notify_via_http(order, trade)
    params = {
      'MessageType' => 'E',
      'OrderReferenceIdentifier' => order['id'],
      'ExecutedShares' => trade['shares'],
      'ExecutionPrice' => trade['price'],
      'MatchNumber' => trade['id'],
      'To' => order['from']
    }
    http = EventMachine::HttpRequest.new(order['broker'], :connect_timeout => 1)
    response = http.post(:body => params)
    unless response.error
      puts "Notified #{order['from']} about #{trade['id']} to status: #{response.response_header.status}"
    else
      puts "Error sending http request!"
      puts response.response
    end
  end

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
          notify_via_http(order, trade)
        end
      end.resume
    end
  end
end
