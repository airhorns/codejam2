require 'will_paginate/collection'

class Snapshot
  KEYS = ['timestamp', 'action', 'orderRef', 'matchNumber', 'amount', 'symbol', 'sellOrderRef', 'buyOrderRef', 'parentOrderRef', 'price', 'state', 'phone']

  def initialize(page = nil, per_page = nil)
    @page = page || 1
    @per_page = per_page || 30
    unless @per_page.to_i >= 1
      @per_page = 30
    end
  end

  def rows
    WillPaginate::Collection.create(@page, @per_page) do |pager|
      _rows = $redis.zrangebyscore('all', '-inf', '+inf', :limit => [pager.offset, pager.per_page])
      _rows = filter_rows(_rows)
      pager.replace _rows
      unless pager.total_entries
        pager.total_entries = $redis.zcard('all')
      end
    end
  end

  def all_rows
    filter_rows($redis.zrangebyscore('all', '-inf', '+inf'))
  end

  ITEM_TO_ROW = {'created' => 'timestamp', 'shares' => 'amount', 'stock' => 'symbol', 'price' => 'price'}
  TRADE_TO_ROW = ITEM_TO_ROW.merge({'buy_order_id' => 'buyOrderRef', 'sell_order_id' => 'sellOrderRef', 'id' => 'matchNumber'})
  ORDER_TO_ROW = ITEM_TO_ROW.merge({'from' => 'phone', 'parent' => 'parentOrderRef', 'twilio' => false, 'broker' => false, 'id' => 'orderRef'})

  def trade_to_row(raw)
    row = apply_transformation(TRADE_TO_ROW, raw)
    row['action'] = 'E'
    fill_in_missing(row)
  end

  def order_to_row(raw)
    row = apply_transformation(ORDER_TO_ROW, raw)
    row['action'] = raw['order_type'][0].upcase
    row['state'] = raw['filled'] == '1' ? 'F' : 'U'
    fill_in_missing(row)
  end

  private

  def filter_rows(rows)
    rows
    .map do |id|
        raw = TradeManager.get(id)
        if raw['from'].nil?
          trade_to_row(raw)
        else
          order_to_row(raw)
        end
      end
    .sort_by {|row| row['timestamp']}
  end

  def fill_in_missing(row)
    KEYS.each do |key|
      row[key] ||= ""
    end
    row
  end

  def apply_transformation(transformation, raw)
    transformation.reduce({}) do |row, (src, dest)|
      row[dest] = raw[src] if dest
      row
    end
  end
end
