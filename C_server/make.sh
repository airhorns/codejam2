gcc -std=c99 -Wall -fPIC -g -ggdb -O2 -I../src/ -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -c -o server.o server.c  
gcc -std=c99 -Wall -fPIC -g -ggdb -O2 -I../src/ -I/usr/include -I/usr/local/include -I./ -D_GNU_SOURCE -o index.cgi server.o libhiredis.a libqdecoder.a -lfcgi 
sudo cp index.cgi /home/www/cgi/
sudo chmod +x /home/www/cgi/ 
