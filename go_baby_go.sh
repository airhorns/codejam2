#ruby exchange_server.rb --daemonize --port=9000 --environment=production
#pid=`cat goliath.pid`
rake test
#echo "Exchange PID: $pid"
ruby notification_daemon.rb start
pid=`ruby notification_daemon.rb status | cut -d[ -f2 | cut -d" " -f 2 | cut -d] -f1`
echo "Notification server PID: $pid"
thin start --daemonize
sleep 1
pid=`cat tmp/pids/thin.pid`
echo "User server PID: $pid"
sudo spawn-fcgi -a127.0.0.1 -p8500 -n /home/www/cgi/index.cgi -C 12 
