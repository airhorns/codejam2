local MAX_ID = 100000000
local stock = KEYS[1]
local order_type = KEYS[2]
local from = ARGV[1]
local shares = tonumber(ARGV[2])
local price = tonumber(ARGV[3])
local twilio = tonumber(ARGV[4])
local broker_address = ARGV[5]
local broker_port = ARGV[6]
local broker_url = ARGV[7]
local created = ARGV[8]

function score(price, id, order_type)
  if order_type == 'buy' then
    return price * MAX_ID + (MAX_ID - id)
  else
    return -1 * (price * MAX_ID + id)
  end
end

function order_set_key(order_type)
  return stock .. '_' .. order_type .. '_orders'
end

function opposite_order_type(given_type)
  if given_type == 'buy' then
    return 'sell'
  else
    return 'buy'
  end
end

function next_order_key(order_type)
  id = redis.call('incr', (stock .. '_' .. order_type .. '_nextid'))
  return id, (stock .. "_" .. order_type .. "_order_" .. id)
end

function store_table(table, key)
  for k,v in pairs(table) do
    redis.call('HSET', key, k, v)
  end
end

function store_order(table, order_type, parent_id)
  local id, next_order_id = next_order_key(order_type)
  if parent_id then
    id_for_score = parent_id
  else
    id_for_score = id
  end
  store_table(table, next_order_id)
  redis.call('HSET', next_order_id, 'id', id)
  redis.call('ZADD', order_set_key(order_type), score(table['price'], id_for_score, order_type), next_order_id)
  return id, next_order_id
end


-- Get the next ID to store the hash in
local current_order_table = {stock = stock, from = from, shares = shares, price = price, twilio = twilio, broker_address = broker_address, broker_port = broker_port, broker_url = broker_url, parent = nil, created = created, filled = 0}

local current_order_id, current_order_key = store_order(current_order_table, order_type)

function execute_trade(against_key, shares, price)
  -- Create a trade with the number of shares in this order
  trade_id, trade_key = next_order_key('trade')
  trade = {shares = shares, id = trade_id, price = price}
  if order_type == 'buy' then
    trade['buy_order'] = current_order_key
    trade['sell_order'] = against_key
  else
    trade['buy_order'] = against_key
    trade['sell_order'] = current_order_key
  end

  store_table(trade, trade_key)
  redis.call('sadd', 'trades', trade_key)
  redis.call('publish', 'trades', trade_key)
  return trade_key
end

-- Fill outstanding orders.
local outstanding_opposites_key = stock .. '_' .. opposite_order_type(order_type) .. '_orders'
local outstanding_opposites = redis.call('ZREVRANGEBYSCORE', outstanding_opposites_key, '+inf', score(price, MAX_ID, opposite_order_type(order_type)))

local unused_shares, processed, parent_key = shares, false

-- For each opposite, decrease the outstanding shares opened by this order
for i, opposite_key in pairs(outstanding_opposites) do
  -- A matching opposite order has been found. Apply it.

  -- THe trade price is the sellers price.
  if order_type == 'sell' then
    trade_price = price
  else
    trade_price = redis.call('HGET', opposite_key, 'price')
  end

  -- We're going to try to fill out all the shares from this outstanding order
  local opposite_shares = redis.call('HGET', opposite_key, 'shares')

  redis.call('HSET', opposite_key, 'filled', 1)               -- Mark the other order as filled
  redis.call('ZREM', outstanding_opposites_key, opposite_key) -- Remove it from the outstanding orders set
  unused_shares = unused_shares - opposite_shares             -- Mark the shares as taken
  processed = true                                            -- Mark the currently-being-added order as filled as well.

  if unused_shares <= 0 then
    -- We've used more than the available shares for this incoming order, so execute a trade only for the amount of unused shares
    parent_key = opposite_key
    -- Here, unused_shares is -ive, so add it back to opposite shares to get the amount which took the old value of unused_shares to 0.
    execute_trade(opposite_key, opposite_shares + unused_shares, trade_price)
    break
  else
    -- Execute a trade for all the shares.
    execute_trade(opposite_key, opposite_shares, trade_price)
  end
end

if unused_shares < 0 then
  -- The last opposite order couldn't be fully filled by this incoming order. It's by now been marked as
  -- filled, so create a partial order pointing to it.
  local parent_price = redis.call('HGET', parent_key, 'price')
  local parent_id = tonumber(redis.call('HGET', parent_key, 'id'))
  partial_order = {stock = stock, from = from, shares = unused_shares * -1, price = parent_price, parent = parent_id}
  store_order(partial_order, opposite_order_type(order_type), parent_id)
elseif unused_shares > 0 and processed then

  -- This currently being added order couldn't be totally fufilled, so create a partial order to point to it.
  partial_order = {stock = stock, from = from, shares = unused_shares, price = price, parent = current_order_key}
  store_order(partial_order, order_type, current_order_id)
end

-- If this order has been filled, mark it as such.
if processed then
  redis.call('HSET', current_order_key, 'filled', '1')
  redis.call('ZREM', order_set_key(order_type), current_order_key)
end

return current_order_key
