class InvalidOrderError < ArgumentError; end

class Order
  attr_reader :stock, :number_from, :shares, :price, :twilio, :order_type, :broker_url

  def initialize(params)
    result = validate(params)
    if result
      raise InvalidOrderError.new(result)
    end
  end

  def validate(params)
    if params['MessageType'] != 'O'
      return 'M'
    end
    @number_from = params['From']
    if @number_from.size > 15 or @number_from.size < 11 or @number_from[0,1] != '+' or (@number_from=~/[0-9]*/)!=0
        return 'F'
    end
    @order_type = params['BS']
    if @order_type != 'B' and @order_type != 'S'
      return 'I'
    end
    @shares = params['Shares'].to_i
    if @shares < 0 or @shares > 999999 or @shares.to_s != params['Shares']
      return 'Z'
    end
    @stock = params['Stock']
    if (@stock =~ /^[a-zA-Z]/) != 0
      if @stock.size > 8 or @stock.size < 3
        return 'S'
      end
    end
    @twilio = params['Twilio']
    if @twilio != 'Y' and @twilio != 'N'
      return 'T'
    else
      @twilio = @twilio == 'Y'
    end

    @price = params['Price'].to_f
    if @price > 100000 or @price < 1
      return "X"
    end

    @broker_port = params['BrokerPort'].to_i
    if @broker_port.to_s != params['BrokerPort']
        return "P"
    end
    @broker_address = params['BrokerAddress']
    #match email address
    if (@broker_address =~ /(.*\.)*.*/) != 0 and @broker_address!='localhost'
      return "A"
    end
    @broker_endpoint = params['BrokerEndpoint']
    if (@broker_endpoint =~ /(.*\/)*.*/) != 0
      return 'E'
    end
    @broker_url = URI::HTTP.build(:host => @broker_address, :port => @broker_port, :path => @broker_endpoint)
    return nil
  end
end
