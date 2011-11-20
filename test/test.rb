require_relative '../stock_manager'
require_relative './test_helper'
@manager = StockManager.new("apple")
@manager.reset!

100.times do
@manager.buy("1234", 50, 91, false, "a")
@manager.buy("1234", 150, 91, false, "a")
@manager.buy("1234", 100, 92, false, "a")
@manager.sell("1234", 200, 90, false, "a")
@manager.sell("1234", 200, 90, false, "a")
@manager.buy("1234", 100, 92, false, "a")
end
