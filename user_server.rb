require "rubygems"
require "bundler/setup"
require 'net/http'
require 'uri'

Bundler.require :default, :web
require File.expand_path('./trade_manager', File.dirname(__FILE__))
require File.expand_path('./snapshot', File.dirname(__FILE__))

SILANIS_UPLOAD_URL = URI('http://ec2-184-73-166-185.compute-1.amazonaws.com/aws/rest/services/codejam/processes')
SILANIS_AUTH_HEADER = 'Basic Y29kZWphbTpzZWNyZXQ='
set :erb, :layout => :application

get '/' do
  'Hello World!'
  erb :index
end

get '/snapshot.?:format?' do
  @rows = Snapshot.new.rows
  if params[:format] && params[:format] == 'json'
    content_type :json
    @rows.to_json
  else
    erb :snapshot
  end
end

get '/snapshot' do
  @rows = Snapshot.new.rows
  erb :snapshot
end

get '/upload_snapshot' do
  req = Net::HTTP::Post.new(SILANIS_UPLOAD_URL.path)
  req['Authorization'] = SILANIS_AUTH_HEADER
  req.content_type = "application/json"
  snapshot = {
    "name" => "Test Signing Process 1",
    "description" => "Codejam Snapshot 1",
    "owner" => {"name" => "Janet", "email" => "harry.brundage@gmail.com"},
    "signer" => {"name" => "Judge Judy", "email" => "harry.brundage@jadedpixel.com" },
    "transactions" => Snapshot.new.rows
  }
  req.body = snapshot.to_json.to_s

  res = Net::HTTP.start(SILANIS_UPLOAD_URL.host, SILANIS_UPLOAD_URL.port) do |http|
    http.request(req)
  end

  case res
  when Net::HTTPSuccess
    return "Snapshot uploaded successfully."
  else
    return res.value
  end
end

get '/recent_trades.json' do
  content_type :json
  TradeManager.recent_trades(10).to_json
end
