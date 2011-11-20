require_relative '../stock_manager'
require_relative './test_helper'
@manager = StockManager.new("apple")
@manager.reset!

@manager.buy("+19176395561", 50, 91, true, "a")
@manager.buy("+19176395561", 150, 91, true, "a")
@manager.buy("+19176395561", 100, 92, true, "a")
@manager.sell("+19176395561", 200, 90, true, "a")
@manager.sell("+19176395561", 200, 90, true, "a")
@manager.buy("+19176395561", 100, 92, true, "a")
