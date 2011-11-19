gcc -Wall -fPIC -g -O2 -I../src/  -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -c -o server.o server.c 
gcc -Wall -fPIC -g -O2 -I../src/  -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -o index.cgi /home/www/cgi-bin/server.o /home/user/qDecoder-11.0.0/src/libqdecoder.a 
chmod +x ./server.c 
