require_relative '../stock_manager'
require_relative './test_helper'
@manager = StockManager.new("apple")
@manager.reset!

20.times do
  older_id = @manager.buy("1234", 100, 100, false, "a")
  younger_id = @manager.buy("1234", 100, 100, false, "a")
  sell_id = @manager.sell("1234", 150, 100, false, "a")
end
