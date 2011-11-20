from twilio-python/twilio.rest import TwilioRestClient

account = "AC888a285988894223a40b8d0df20d6d58"
token = "6ea425d908a216d20d505eb013d55985"
client = TwilioRestClient(account, token)

message = client.sms.messages.create(to="+15148834314", from_="+15148005440",
                                     body="test - python")
