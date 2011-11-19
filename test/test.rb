require_relative '../stock_manager'
@manager = StockManager.new("apple")
@manager.reset!
id = @manager.sell("1234", 50, 100, false, "a", "b", "c")
other_id = @manager.buy("1234", 50, 100, false, "a", "b", "c")
