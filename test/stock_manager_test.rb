require_relative './test_helper'
require_relative '../stock_manager'

class SockManagerTest < MiniTest::Unit::TestCase
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
    @manager.sell("1234", 50, 100, false, "a", "b", "c")
    @manager.buy("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
  end

  def test_multiple_sell_orders_for_the_same_price_should_be_filled_by_buy_orders
    @manager.sell("1234", 50, 100, false, "a", "b", "c")
    @manager.sell("1234", 50, 100, false, "a", "b", "c")
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
  end

  def test_multiple_buy_orders_for_the_same_price_should_be_filled_by_sell_orders
    @manager.buy("1234", 50, 100, false, "a", "b", "c")
    @manager.buy("1234", 50, 100, false, "a", "b", "c")
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
  end

  def test_partially_filled_buy_orders_should_leave_partials
    @manager.buy("1234", 100, 100, false, "a", "b", "c")
    @manager.sell("1234", 50, 100, false, "a", "b", "c")
    assert_equal 0, @manager.outstanding_sell_orders
    assert_equal 1, @manager.outstanding_buy_orders
  end

  def test_partially_filled_sell_orders_should_leave_partials
    @manager.sell("1234", 100, 100, false, "a", "b", "c")
    @manager.buy("1234", 50, 100, false, "a", "b", "c")
    assert_equal 1, @manager.outstanding_sell_orders
    assert_equal 0, @manager.outstanding_buy_orders
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
end
