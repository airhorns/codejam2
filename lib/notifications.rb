module Notifications
  ACCOUNT_SID = "ACfe0c2ad14e11f0d1eeff1cd6fdc34a57"
  AUTH_TOKEN = "9868ece9300972904fa9730d19a24b02"
  NUMBER = "+15148005441"

  # set up a client to talk to the Twilio REST API
  EM::Twilio.authenticate(ACCOUNT_SID, AUTH_TOKEN)

  def self.notify_via_http(order, trade)
    params = {
      'MessageType' => 'E',
      'OrderReferenceIdentifier' => order['id'],
      'ExecutedShares' => trade['shares'],
      'ExecutionPrice' => trade['price'],
      'MatchNumber' => trade['id'],
      'To' => order['from']
    }
    http = EventMachine::HttpRequest.new(order['broker'], :connect_timeout => 1)
    response = http.post(:body => params)
    unless response.error
      puts "Notified #{order['from']} about T#{trade['id']} to status: #{response.response_header.status}"
    else
      puts "Error sending http request!"
      puts response.response
    end
  end

  def self.notify_via_sms(order, trade)
    EM::Twilio.send_sms order['from'], NUMBER, sms_body(order, trade) do |response|
      if response.success?
        puts "Notified #{order['from']} about T#{trade['id']} via SMS"
      else
        puts response.error
      end
    end
  end

  def self.sms_body(order, trade)
    "Your order #{order['id']} has been executed for #{trade['shares']} shares. Your match # is #{trade['id']} and the trade executed at #{trade['price'].to_f / 100} per share."
  end
end
