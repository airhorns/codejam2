thin stop
kill `cat goliath.pid`
ruby notification_daemon.rb stop
rm *.pid
mkdir -p log
mv *.log log/
