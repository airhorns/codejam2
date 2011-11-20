thin stop
kill `cat goliath.pid`
ruby notification_daemon.rb stop
rm -f *.pid
mkdir -p log
mv -f *.log log/
