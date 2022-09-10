#! /bin/bash
sudo yum update -y
sudo yum -y upgrade
sudo service iptables stop
sudo chkconfig iptables off
curl -O  http://www.softether-download.com/files/softether/v4.38-9760-rtm-2021.08.17-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz
tar -xvzf softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz
sudo yum -y groupinstall "Development Tools"
cd vpnserver\
make
cd ..
sudo mv vpnserver /usr/local/src
sudo chmod 0710 /usr/local/src/vpnserver/*
cd /usr/local/src/vpnserver
make
sudo cat <<\EOF > vpnserver
#!/bin/bash
# chkconfig: 2345 99 01
# description: SoftEther VPN Server
DAEMON=/usr/local/src/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
echo $1
test -x $DAEMON || exit 0

case "$1" in
start)
$DAEMON start
touch $LOCK
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF



sudo cp vpnserver /etc/init.d/vpnserver
sudo chmod 0710 /etc/init.d/vpnserver
sudo /etc/init.d/vpnserver
chkconfig --add vpnserver
