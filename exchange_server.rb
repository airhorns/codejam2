require 'rubygems'
require 'bundler/setup'

Bundler.require :server

require 'em-synchrony'

$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")

require File.expand_path './stock_manager', File.dirname(__FILE__)

class ExchangeRunner < Goliath::API
  use Goliath::Rack::Params

  def response(env)
    begin
      order = Order.new(params)
      manager = StockManager.new(order.stock)
      id = if order.order_type == 'B'
        manager.buy(order.number_from, order.shares, order.price, order.twilio, order.broker_url)
      else
        manager.sell(order.number_from, order.shares, order.price, order.twilio, order.broker_url)
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

class InvalidOrderError < ArgumentError; end

class Order
  attr_reader :stock, :number_from, :shares, :price, :twilio, :order_type

  def initialize(params)
    result = validate(params)
    if result
      raise InvalidOrderError.new(result)
    end
  end

  def broker_url
    "#{@broker_address}:#{@broker_port}/#{@broker_endpoint}"
  end

  def validate(params)
    if params['MessageType'] != 'O'
      return 'M'
    end
    @number_from = params['From']
    if @number_from.size > 15 or @number_from.size < 11 or @number_from[0,1] != '+' or (@number_from=~/[0-9]*/)!=0
        return 'F'
    end
    @order_type = params['BS']
    if @order_type != 'B' and @order_type != 'S'
      return 'I'
    end
    @shares = params['Shares'].to_i
    if @shares < 0 or @shares > 999999 or @shares.to_s != params['Shares']
      return 'Z'
    end
    @stock = params['Stock']
    if (@stock =~ /^[a-zA-Z]/) != 0
      if @stock.size > 8 or @stock.size < 3
        return 'S'
      end
    end
    @twilio = params['Twilio']
    if @twilio != 'Y' and @twilio != 'N'
      return 'T'
    else
      @twilio = @twilio == 'Y'
    end

    @price = params['Price'].to_f
    if @price > 100000 or @price < 1
      return "X"
    end
    @broker_port = params['BrokerPort'].to_i
    if @broker_port.to_s != params['BrokerPort']
        return "P"
    end
    @broker_address = params['BrokerAddress']
    #match email address
    if (@broker_address =~ /(.*\.)*.*/) != 0 and @broker_address!='localhost'
      return "A"
    end
    @broker_endpoint = params['BrokerEndpoint']
    if (@broker_endpoint =~ /(.*\/)*.*/) != 0
      return 'E'
    end
    return nil
  end
end
