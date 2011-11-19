#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "qdecoder.h"
#include "hiredis.h"

//sync


int main(void)
{
    printf("Content-Type: text/plain \n\n");
    //Q_ENTRY *req = qCgiRequestParse(NULL);
    Q_ENTRY *req = qCgiRequestParse(NULL,0 );
    const char *MessageType = req->getStr(req,"MessageType",false);
    const char *From = req->getStr(req,"From",false);
    const char *BS = req->getStr(req,"BS",false);
    const int Shares = req->getInt(req,"Shares");
    const char *Stock = req->getStr(req,"Stock",false);
    const int Price = req->getInt(req,"Price");
    const char *Twilio = req->getStr(req,"Twilio",false);
    const char *BrokerAddr = req->getStr(req,"BrokerAddress",false);
    const int BrokerPort = req->getInt(req,"BrokerPort");
    const char *BrokerEndPoint = req->getStr(req,"BrokerEndpoint",false);
    free(req);
    printf("MessageType = %s\n",MessageType);
    printf("From = %s\n",From);
    printf("BS = %s\n",BS);
    printf("Shares = %d\n",Shares);
    printf("Stock = %s\n",Stock);
    printf("Price = %d\n",Price);
    printf("Twilio = %s\n",Twilio);
    printf("BrokerAddress = %s\n",BrokerAddr);
    printf("BrokerPort = %d\n",BrokerPort);
    printf("BrokerEndPoint = %s\n",BrokerEndPoint);

    char *retStr = malloc(sizeof(char)*400);
    strcat(retStr, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Response>\n<Exchange>");
//VALIDATION
    int failure = 0;
    char * failMsg = malloc(sizeof(char)*25);
    if ( strcmp(MessageType, "O") != 0)
	 { failure = 1; failMsg = "<Reject Reason=\"M\" />";}  

    else if (From[0] != '+' || strlen(From) > 16 || strlen(From) < 11 )
	 { failure = 1; failMsg = "<Reject Reason=\"F\" />";}  
    else if (strcmp(BS, "B") != 0 && strcmp(BS,"S")!=0) 
	 { failure = 1; failMsg = "<Reject Reason=\"I\" />";}  
    else if (Shares < 1 || Shares >= 1000000) 
	 { failure = 1; failMsg = "<Reject Reason=\"Z\" />";}  
    else if (Price < 1 || Price >= 100000) 
	 { failure = 1; failMsg = "<Reject Reason=\"X\" />";}  
    else if (strlen(Stock) < 3 || strlen(Stock) > 8) 
	 { failure = 1; failMsg = "<Reject Reason=\"S\" />";}  //FIXME: missing alphanumerical validation...
    else if (strcmp(Twilio, "Y") != 0 && strcmp(Twilio ,"N") !=0 ) 
	 { failure = 1; failMsg = "<Reject Reason=\"T\" />";}  
    else if (BrokerPort < 10 || BrokerPort > 99999) 
	 { failure = 1; failMsg = "<Reject Reason=\"P\" />";}  

    else
    {
	//Verfify phone
	int phone_len = strlen(From);
	int ii;
	for (ii = 1 ; ii < phone_len;ii++)
	{
	    if ( From[ii] < 48 || From[ii] > 57) //assers it is an integer
		{ failure = 1; failMsg = "<Reject Reason=\"F\" />"; goto end_verification;}  
	}
	//verify stock
	int strLen = strlen(Stock);
	for (ii = 0 ; ii < strLen;ii++)
	{
	    if ( (Stock[ii] < 48 || Stock[ii] > 57) 
		&& (BrokerAddr[ii] < 65 || BrokerAddr[ii] > 90)
		&& (BrokerAddr[ii] < 97 || BrokerAddr[ii] > 122)) 
		{ failure = 1; failMsg = "<Reject Reason=\"S\" />"; goto end_verification;}  
	}
	//
	strLen = strlen(BrokerAddr);
	if (strLen < 4)
		{ failure = 1; failMsg = "<Reject Reason=\"A\" />"; goto end_verification;}  
	for (ii = 0 ; ii < strLen;ii++)
	{
	    if ( (BrokerAddr[ii] < 48 || BrokerAddr[ii] > 57) 
		&& (BrokerAddr[ii] != 46) && (BrokerAddr[ii] != 45) && (BrokerAddr[ii] != 95)
		&& (BrokerAddr[ii] < 65 || BrokerAddr[ii] > 90)
		&& (BrokerAddr[ii] < 97 || BrokerAddr[ii] > 122)) 
		{ failure = 1; failMsg = "<Reject Reason=\"A\" />"; goto end_verification;}  
	}
	
	//verify BrokerEndpoint
	if (strlen(BrokerEndPoint) < 1) 
	    { failure = 1; failMsg = "<Reject Reason=\"E\" />"; goto end_verification;}  

    }
    
end_verification:
    //TODO: phone verification
    //
    if ( failure == 1) {strcat(retStr,failMsg);}
    else 
    {
	//construct broker string:
	char *broker = malloc(sizeof(char)*1000);
	strcat(broker,BrokerAddr);
	strcat(broker,":");
	strcat(broker,BrokerPort);
	strcat(broker,BrokerEndPoint);

	redisContext *redC;
	redisReply *rreply;
    
	struct timeval timeout = { 1, 500000 }; // 1.5 seconds
	c = redisConnectWithTimeout((char*)"127.0.0.2", 6379, timeout);
	if (c->err) {
	    printf("Connection error: %s\n", c->errstr); //FIXME: do we return something to the broker?
            exit(1);
	}
	
	//ALL THE LOGIC!!!!
	reply = redisCommand(c,
	    "eval FUNC!!!!! 7 %s %s %s %s %s %s %s ",
	    From,
	    BS,
	    Shares,
	    Stock,
	    Price,
	    Twilio,
	    broker );

	printf("SET (binary API): %s\n", reply->str);
        freeReplyObject(reply);
	
	free (broker);
	strcat(retStr, "<Accept OrderRefId=\"1\" />");
    }
    char *suffix = "</Exchange>\n</Response>\n";
    strcat(retStr,suffix);    
    printf("%s\n",retStr);
    //TODO: reply
 //   free (retStr);
    
    return 0;
}
