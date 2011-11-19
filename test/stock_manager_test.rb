require_relative './test_helper'
require_relative '../stock_manager'

class StockManagerTest < MiniTest::Unit::TestCase
  def setup
    @manager = StockManager.new("apple")
    @manager.reset!
  end

  def test_should_accept_buy_orders
    id = @manager.buy("1234", 50, 91, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_buy_orders
    assert !@manager.filled?(id)
  end

  def test_should_accept_sell_orders
    id = @manager.sell("1234", 50, 91, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert !@manager.filled?(id)
  end

  def test_buy_orders_for_a_higher_price_should_be_filled_by_sell_orders
    buy_id = @manager.buy("1234", 50, 105, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_buy_orders
    assert_equal 0, @manager.outstanding_sell_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(buy_id)
  end

  def test_sell_orders_for_a_lower_price_should_be_filled_by_buy_orders
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    buy_id = @manager.buy("1234", 50, 105, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(buy_id)
  end

  def test_buy_orders_for_the_same_price_should_be_filled_by_sell_orders
    buy_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(buy_id)
  end

  def test_sell_orders_for_the_same_price_should_be_filled_by_buy_orders
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    buy_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(buy_id)
  end

  def test_multiple_sell_orders_for_the_same_price_should_be_filled_by_buy_orders
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    sell2_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    assert !@manager.filled?(sell_id)
    assert !@manager.filled?(sell2_id)
    buy_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(sell2_id)
    assert @manager.filled?(buy_id)
  end

  def test_multiple_buy_orders_for_the_same_price_should_be_filled_by_sell_orders
    buy_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
    buy2_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
    assert !@manager.filled?(buy_id)
    assert !@manager.filled?(buy2_id)
    sell_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(buy_id)
    assert @manager.filled?(buy2_id)
    assert @manager.filled?(sell_id)
  end

  def test_partially_filled_buy_orders_should_leave_partials
    buy_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
    assert @manager.filled?(buy_id)
    assert @manager.filled?(sell_id)
  end

  def test_partially_filled_sell_orders_should_leave_partials
    sell_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    buy_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(buy_id)
    assert @manager.filled?(sell_id)
  end

  def test_multiple_sell_orders_should_be_filled_by_a_larger_buy_order_leaving_a_partial
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 250, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
  end

  def test_multiple_sell_orders_should_be_filled_by_a_smaller_buy_order_leaving_a_partial
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 150, 100, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
  end

  def test_multiple_buy_orders_should_be_filled_by_a_larger_sell_order_leaving_a_partial
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 250, 90, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
  end

  def test_multiple_buy_orders_should_be_filled_by_a_smaller_sell_order_leaving_a_partial
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 150, 90, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
  end

  def test_higher_priced_buy_orders_should_be_filled_first
    unfilled_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    filled1_id = @manager.buy("1234", 100, 105, false, "a", "b", "c")
    filled2_id = @manager.buy("1234", 100, 110, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 200, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(filled1_id)
    assert @manager.filled?(filled2_id)
    assert !@manager.filled?(unfilled_id)
  end

  def test_lower_priced_sell_orders_should_be_filled_first
    unfilled_id = @manager.sell("1234", 100, 110, false, "a", "b", "c")
    filled1_id = @manager.sell("1234", 100, 105, false, "a", "b", "c")
    filled2_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    buy_id = @manager.buy("1234", 200, 120, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(buy_id)
    assert @manager.filled?(filled1_id)
    assert @manager.filled?(filled2_id)
    assert !@manager.filled?(unfilled_id)
  end

  def test_earlier_created_buy_orders_should_be_filled_first
    filled1_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    filled2_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    unfilled_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 200, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
    assert @manager.filled?(sell_id)
    assert @manager.filled?(filled1_id)
    assert @manager.filled?(filled2_id)
    assert !@manager.filled?(unfilled_id)
  end

  def test_earlier_created_sell_orders_should_be_filled_first
    filled1_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    filled2_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    unfilled_id = @manager.sell("1234", 100, 100, false, "a", "b", "c")
    buy_id = @manager.buy("1234", 200, 120, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
    assert @manager.filled?(buy_id)
    assert @manager.filled?(filled1_id)
    assert @manager.filled?(filled2_id)
    assert !@manager.filled?(unfilled_id)
  end

  def test_buying_creates_a_trade
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    assert_equal 1, @manager.trade_count
  end

  def test_selling_creates_a_trade
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    assert_equal 1, @manager.trade_count
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
    @manager.buy("1234", 200, 100, false, "a", "b", "c")
    @manager.sell("1234", 200, 100, false, "a", "b", "c")

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
    @manager.buy("1234", 200, 100, false, "a", "b", "c")
    @manager.sell("1234", 300, 100, false, "a", "b", "c")

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
    older_id = @manager.buy("1234", 200, 100, false, "a", "b", "c")
    younger_id = @manager.buy("1234", 200, 100, false, "a", "b", "c")
    sell_id = @manager.sell("1234", 200, 100, false, "a", "b", "c")

    wire.join

    assert_equal "200", @trade['shares']
    assert_equal "100", @trade['price']
  end
end
