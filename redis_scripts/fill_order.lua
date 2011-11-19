local stock = KEYS[1]
local order_type = KEYS[2]
local from = ARGV[1]
local shares = tonumber(ARGV[2])
local price = tonumber(ARGV[3])
local twilio = tonumber(ARGV[4])
local broker_address = ARGV[5]
local broker_port = ARGV[6]
local broker_url = ARGV[7]

-- Get the next ID to store the hash in
local next_order_id = redis.call('incr', (stock .. '_' .. order_type .. '_nextid'))

local hash = {stock = stock, from = from, shares = shares, price = price, twilio = twilio, broker_address = broker_address, broker_port = broker_port, broker_url = broker_url, parent = nil}

-- Store the hash of attributes
redis.call('hset', next_order_id, hash)

-- Store the ID of the hash in the orders sorted set for the stock
redis.call('zadd', (stock .. '_orders'), price, next_order_id)

return 0


