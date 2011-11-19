require_relative '../stock_manager'
require_relative './test_helper'
@manager = StockManager.new("apple")
@manager.reset!

    listening = false
    wire = Wire.new do
      r = Redis.new
      r.subscribe 'trades' do |on|
        on.subscribe do |channel|
          listening = true
        end

        on.message do |channel, message|
          @trade = @manager.get(message)
          r.unsubscribe
        end

      end
    end

    Wire.pass while !listening
    older_id = @manager.buy("1234", 200, 100, false, "a", "b", "c")
    younger_id = @manager.buy("1234", 200, 100, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 200, 100, false, "a", "b", "c")

    wire.join

puts @trade
