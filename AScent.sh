#!/bin/bash
clear

HOST=""
USER=""
HUB=""
BRIDGE=""
SE_PASSWORD=""
 
 
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
 
 
echo -n "Enter Server IP: "
read HOST
echo -n "Set Virtual Hub: "
read HUB
echo -n "Set ${HUB} Hub Username: "
read USER
echo -n "Set ${HOST} Server Password: "
read SE_PASSWORD
echo " "
echo "Have some coffee while waiting for this to finish."
echo " "
yum -y upgrade
yum -y groupinstall "Development Tools"
yum -y install gcc zlib-devel openssl-devel readline-devel ncurses-devel wget tar dnsmasq net-tools iptables-services system-config-firewall-tui nano iptables-services
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 
systemctl disable firewalld
systemctl stop firewalld
systemctl status firewalld
service iptables save
service iptables stop
chkconfig iptables off
cd /usr/local
wget http://www.softether-download.com/files/softether/v4.25-9656-rtm-2018.01.15-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.25-9656-rtm-2018.01.15-linux-x64-64bit.tar.gz
tar xzvf softether-vpnserver-v4.25-9656-rtm-2018.01.15-linux-x64-64bit.tar.gz
cd /usr/local/vpnserver
make
echo '#!/bin/sh
### BEGIN INIT INFO
# Provides: vpnserver
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start daemon at boot time
# Description: Enable Softether by daemon.
### END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=192.168.7.1

test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
sleep 3
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
sleep 1
/sbin/ifconfig tap_soft $TAP_ADDR
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0' > /etc/init.d/vpnserver
#
chmod +x /etc/init.d/vpnserver
#
/etc/init.d/vpnserver start
#
systemctl enable vpnserver
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
TARGET="/usr/local/"
${TARGET}vpnserver/vpncmd localhost /SERVER /CMD ServerPasswordSet ${SE_PASSWORD}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubCreate ${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserCreate ${USER} /GROUP:none /REALNAME:none /NOTE:none
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /HUB:${HUB} /CMD UserAnonymousSet ${USER}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:vpn /DEFAULTHUB:${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD HubDelete DEFAULT
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD BridgeCreate /DEVICE:"soft" /TAP:yes ${HUB}
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD VpnOverIcmpDnsEnable /ICMP:yes /DNS:yes
${TARGET}vpnserver/vpncmd localhost /SERVER /PASSWORD:${SE_PASSWORD} /CMD ListenerCreate 53
cd ..
HOST=${HOST}
USER=${USER}
HUB=${HUB}
SE_PASSWORD=${SE_PASSWORD}
service vpnserver stop
#
echo interface=tap_soft >> /etc/dnsmasq.conf
echo dhcp-range=tap_soft,192.168.7.0,192.168.7.254,12h >> /etc/dnsmasq.conf
echo dhcp-option=tap_soft,3,192.168.7.1 >> /etc/dnsmasq.conf
echo port=0 >> /etc/dnsmasq.conf
echo dhcp-option=option:dns-server,8.8.8.8 >> /etc/dnsmasq.conf
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.d/ipv4_forwarding.conf
#
sysctl --system
#
iptables -F -t nat
#
echo 1 > /proc/sys/net/ipv4/ip_forward
#
iptables -t nat -A POSTROUTING -s 192.168.7.0/24 -j SNAT --to-source ${HOST}
#
iptables-save > /etc/sysconfig/iptables
#
service vpnserver start
#
systemctl start dnsmasq
#
systemctl enable dnsmasq
#
chkconfig vpnserver on
