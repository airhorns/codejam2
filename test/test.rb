require_relative '../stock_manager'
@manager = StockManager.new("apple")
@manager.reset!
unfilled_id = @manager.buy("1234", 100, 100, false, "a", "b", "c")
filled1_id = @manager.buy("1234", 100, 105, false, "a", "b", "c")
filled2_id = @manager.buy("1234", 100, 110, false, "a", "b", "c")
sell_id = @manager.sell("1234", 200, 100, false, "a", "b", "c")
puts @manager.outstanding_buy_orders
puts @manager.outstanding_sell_orders
puts @manager.get(unfilled_id)
