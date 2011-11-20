# -*- coding: utf-8 -*-

require 'rubygems'  
require 'sinatra'
require 'redis'
require File.expand_path('./stock_manager', File.dirname(__FILE__))
require "bundler/setup"
Bundler.require :default, :web
$:.unshift File.expand_path('.', File.dirname(__FILE__))
$redis = Redis::Scripted.connect(scripts_path: "./redis_scripts")
@order_type="";
@broker_address="";
@broker_port=80;
@broker_endpoint="";
@number_from=0;
@stock="";
@twilio="";
@price=0;
@shares=0;
get '/' do  
  "You are on the server page for codejam2!"
end
    
post '/' do
  s = validate_order(params)
  if s == nil
    id = 0;
    manager = StockManager.new(@stock);
    if @broker_endpoint.chr == "/" 
      broker_url = "#{@broker_address}:#{@broker_port}#{@broker_endpoint}"
    else 
      broker_url = "#{@broker_address}:#{@broker_port}/#{@broker_endpoint}"
    end
    puts broker_url
    if @order_type=='B'
      id = manager.buy(@number_from, @shares, @price, @twilio, broker_url);
    else
      id = manager.sell(@number_from, @shares, @price, @twilio, broker_url);
    end
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
     <Response>
     <Exchange><Accept OrderRefId=\"#{@order_type}#{id}\" /></Exchange>
     </Response>"
  else
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
     <Response>
     <Exchange><Reject Reason=\"#{s}\" /></Exchange>
     </Response>"
  end
  
end

not_found do  
  halt 404, 'page not found'  
end

def validate_order(params)
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
  end
  @price = params['Price'].to_f
  if @price > 1000.00 or @price < 0.01
    return "X" 
  end
  @broker_port = params['BrokerPort'].to_i
  #Check inputs are numbers
  if @broker_port.size > 5 or @broker_port.size < 2 or @broker_port.to_s != params['BrokerPort']
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
