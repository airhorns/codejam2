require File.expand_path './test_helper', File.dirname(__FILE__)
require 'stock_manager'

class StockManagerTradesTest < MiniTest::Unit::TestCase
  def setup
    @manager = StockManager.new("apple")
    @manager.reset!
  end

  def test_trade_is_published_for_even_sales
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
    @manager.buy("1234", 200, 100, false, "a")
    @manager.sell("1234", 200, 100, false, "a")

    wire.join

    assert_equal "200", @trade['shares']
    assert_equal "100", @trade['price']
  end

  def test_trade_is_published_for_uneven_sales
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
    @manager.buy("1234", 200, 100, false, "a")
    @manager.sell("1234", 300, 100, false, "a")

    wire.join

    assert_equal "200", @trade['shares']
    assert_equal "100", @trade['price']
  end

  def test_trade_is_given_proper_reference_id
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
    older_id = @manager.buy("1234", 200, 100, false, "a")
    younger_id = @manager.buy("1234", 200, 100, false, "a")
    sell_id = @manager.sell("1234", 200, 100, false, "a")

    wire.join
    assert_equal older_id, @trade['buy_order']
    assert_equal sell_id, @trade['sell_order']
  end
end
