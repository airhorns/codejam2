gcc -std=c99 -Wall -fPIC -g -ggdb -O2 -I../src/  -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -c -o server.o server.c 
gcc -std=c99 -Wall -fPIC -g -ggdb -O2 -I../src/  -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -o index.cgi server.o libhiredis.a  /home/user/qDecoder-11.0.0/src/libqdecoder.a 
sudo cp index.cgi /home/www/cgi-bin/
sudo chmod +x /home/www/cgi-bin/ 
