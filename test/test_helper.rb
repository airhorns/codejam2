require "rubygems"
require "bundler/setup"

Bundler.require :default, :test
driver = :standard
if driver == :synchrony
  # Make cutest fiber + eventmachine aware if the synchrony driver is used.
  undef test if defined? test
  def test(name = nil, &block)
    cutest[:test] = name

    blk = Proc.new do
      prepare.each { |blk| blk.call }
      block.call(setup && setup.call)
    end

    t = Thread.current[:cutest]
    if defined? EventMachine
      EM.synchrony do
        Thread.current[:cutest] = t
        blk.call
        EM.stop
      end
    else
      blk.call
    end
  end

  class Wire < Fiber
    # We cannot run this fiber explicitly because EM schedules it. Resuming the
    # current fiber on the next tick to let the reactor do work.
    def self.pass
      f = Fiber.current
      EM.next_tick { f.resume }
      Fiber.yield
    end

    def self.sleep(sec)
      EM::Synchrony.sleep(sec)
    end

    def initialize(&blk)
      super

      # Schedule run in next tick
      EM.next_tick { resume }
    end

    def join
      self.class.pass while alive?
    end
  end
else
  class Wire < Thread
    def self.sleep(sec)
      Kernel.sleep(sec)
    end
  end
end
