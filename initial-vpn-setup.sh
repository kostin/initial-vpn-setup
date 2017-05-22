#!/bin/bash

DLPATH='https://github.com/kostin/initial-vpn-setup/raw/master'

rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum -y install epel-release
sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo

yum -y install pptpd curl bind-utils pwgen

if grep -q 'CentOS release 6' /etc/redhat-release; then
	clear
	echo 'Starting install pptpd on '`hostname`
	echo 'Press Enter to continue (Ctrl+C to exit)!'
	read
else
	echo 'Wrong OS!';
	exit 0;
fi

USER=`hostname -s``pwgen 6 1`
DEV=`route | grep '^default' | grep -o '[^ ]*$'`
IP=`ip addr show $DEV | grep 'inet ' | awk '{print $2}' | awk -F/ '{print $1}'`
PASS=`pwgen 32 1`

echo "localip $IP" >> /etc/pptpd.conf
echo "remoteip 10.0.0.100-200" >> /etc/pptpd.conf

echo "$USER pptpd $PASS *" >> /etc/ppp/chap-secrets

> /etc/ppp/options
echo "ms-dns 77.88.8.8" >> /etc/ppp/options
echo "ms-dns 77.88.8.1" >> /etc/ppp/options
echo "lock" >> /etc/ppp/options
echo "name pptpd" >> /etc/ppp/options
echo "require-mschap-v2" >> /etc/ppp/options
echo "require-mppe-128" >> /etc/ppp/options

service pptpd start

sed -i -e 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p

service iptables start
iptables -t nat -A POSTROUTING -o $DEV -j MASQUERADE && iptables-save
service iptables save
chkconfig iptables on

service pptpd restart-kill && service pptpd start

chkconfig pptpd on

echo "PPTP user: $USER"
echo "PPTP password: $PASS"
echo "PPTP server: $IP"
