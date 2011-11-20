require_relative '../stock_manager'
require_relative './test_helper'
@manager = StockManager.new("apple")
@manager.reset!

@manager.buy("1234", 50, 91, true, "a")
@manager.buy("1234", 150, 91, true, "a")
@manager.buy("1234", 100, 92, true, "a")
@manager.sell("1234", 200, 90, true, "a")
@manager.sell("1234", 200, 90, true, "a")
@manager.buy("1234", 100, 92, true, "a")
