require 'rubygems'
require 'bundler/setup'


Bundler.require :server

$: << '.' << './lib'
require 'stock_manager'
require 'order'

$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")

class ExchangeRunner < Goliath::API
  use Goliath::Rack::Params

  def response(env)
    begin
      order = Order.new(params)
      manager = StockManager.new(order.stock)
      id = if order.order_type == 'B'
        manager.buy(order.number_from, order.shares, order.price, order.twilio, order.broker_url.to_s)
      else
        manager.sell(order.number_from, order.shares, order.price, order.twilio, order.broker_url.to_s)
      end
      resp = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Response>
  <Exchange><Accept OrderRefId=\"#{id}\" /></Exchange>
</Response>"
      [200, {}, resp]
    rescue InvalidOrderError => e
      resp = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Response>
  <Exchange><Reject Reason=\"#{e.message}\" /></Exchange>
</Response>"
       [400, {}, resp]
    end
  end
end

class ExchangeServer < Goliath::API
  use Goliath::Rack::Heartbeat

  get '/reset' do
    run Proc.new { |env|
      StockManager.new('').reset!
      [200, {}, ["Reset successfully."]]
    }
  end

  post '/exchange/endpoint' do
    run ExchangeRunner.new
  end

  not_found('/') do
    run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["Try /version /hello_world, /bonjour, or /hola"]] }
  end
end
