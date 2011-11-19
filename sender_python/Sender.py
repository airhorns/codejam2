from twilio-python/twilio.rest import TwilioRestClient
import redis, threading

account = "AC888a285988894223a40b8d0df20d6d58"
token = "6ea425d908a216d20d505eb013d55985"
client = TwilioRestClient(account, token)

class Sender(object):
    def __init__ (self):
	self._redis_sub = redis.Redis(host='localhost', port=6379, db=0)
	self._sub_thread = threading.Thread(target=self._listen)
        self._sub_thread.setDaemon(True)
        self._sub_thread.start()
    
    def _listen(self):
	for message in self._redis_sub.listen():
	    #get data from message, and send it via the API
	    to_num = #TODO: get data from message
	    msg_body =""
	    msg_body = msg_body + "Your order " + ORDERNUM + " has been executed on for " + ExecShares + " shares. Match number is " + MatchNum + ". Execution price is " + ExecPrice + " per share."

	    msg = client.sms.messages.create(
		to=to_num, 
		from_="+15148005440", #hardcoded?
		body=msg_body);
