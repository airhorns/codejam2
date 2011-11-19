#!/usr/bin/env ruby

require "digest/sha1"
puts Digest::SHA1.hexdigest(File.read('./redis_scripts/fill_order.lua'))
