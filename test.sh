#!/bin/bash

ip=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eth0 | awk -F= '{print $2}'`

rpm -Uvh http://apt.sw.be/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
yum -y  install openvpn-2.2.0 lzo-2.04 openvpn-auth-ldap
modprobe tun

\cp -r /usr/share/doc/openvpn-2.2.0/easy-rsa/ /etc/openvpn/
\cp /usr/share/doc/openvpn-2.2.0/sample-config-files/server.conf /etc/openvpn/
cd /etc/openvpn/easy-rsa/2.0/
chmod a+x ./*
. ./vars
./clean-all
source ./vars

echo -e "\n\n\n\n\n\n\n" | ./build-ca
clear
echo "####################################"
echo " CA ..............."
echo "####################################"
./build-key-server gamewaveBJ
./build-dh
#cp keys/{ca.crt,ca.key,server.crt,server.key,dh1024.pem} /etc/openvpn/
\cp keys/ca.crt /etc/openvpn
\cp keys/dh1024.pem /etc/openvpn
\cp keys/gamewaveBJ.key /etc/openvpn
\cp keys/gamewaveBJ.crt /etc/openvpn




opvpn='
mode server
duplicate-cn
port 1194
proto udp
dev tun
ca ca.crt
cert gamewaveBJ.crt
key gamewaveBJ.key
dh dh1024.pem
server 192.168.88.0 255.255.255.0.
push "dhcp-option DNS 8.8.8.8"
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
plugin /usr/lib64/openvpn/plugin/lib/openvpn-auth-ldap.so /etc/openvpn/auth/ldap.conf
client-cert-not-required
username-as-common-name
client-to-client
log-append openvpn.log
keepalive 10 120
comp-lzo
persist-key
persist-tun
status server-tcp.log
verb 3'
echo "$opvpn" > /etc/openvpn/server.conf



cat  > /etc/openvpn/auth/ldap.conf  <<SKS
<LDAP>
    # LDAP server URL
    URL ldap://202.55.225.188

    # Bind DN (If your LDAP server doesn't support anonymous binds)
    BindDN cn=vmail,dc=marketing,dc=com

    # Bind Password
    Password sAAzE5v6mj1a7Hx51smG7olcECcFh7

    # Network timeout (in seconds)
    Timeout 15

    # Enable Start TLS
    TLSEnable no
</LDAP>
<Authorization>
    # Base DN
    BaseDN "o=domains,dc=marketing,dc=com"

    # User Search Filter
    SearchFilter "(&(mail=%u)(accountStatus=active)(enabledService=vpn))"

    # Require Group Membership
    RequireGroup false
</Authorization>
SKS


echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 192.168.88.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/sysctl.conf
sysctl -p



/etc/init.d/openvpn start

