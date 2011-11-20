require "rubygems"
require "bundler/setup"
require 'net/http'
require 'uri'

Bundler.require :http
$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")
subscriber = Redis.new

$: << "."
require 'trade_manager'


def notify_via_http(order, trade)
  http = EventMachine::HttpRequest.new(order['broker'], :connect_timeout => 1)
  http.post({
    'MessageType' => 'E',
    'OrderReferenceIdentifier' => order['id'],
    'ExecutedShares' => trade['shares'],
    'ExecutionPrice' => trade['price'],
    'MatchNumber' => trade['id'],
    'to' => order['from']
  })

  http.errback {
    puts "Error sending http request!"
    puts http
  }

  http.callback {
    puts "Notified #{order['from']} about #{trade['id']} to status: #{http.response_header.status}"
  }
end

subscriber.subscribe('trades') do |on|
  on.message do |channel, message|
    trade = TradeManager.get(message)
    buy_order = TradeManager.get_root(trade['buy_order'])
    sell_order = TradeManager.get_root(trade['sell_order'])

    [buy_order, sell_order].each do |order|
      notify_via_http(order, trade)
    end
  end
end

