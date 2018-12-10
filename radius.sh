#!/bin/sh

apt-get update
apt-get install   -y unzip build-essential  wget libgmp3-dev bison flex
wget https://github.com/FreeRADIUS/freeradius-client/archive/master.zip
unzip master.zip
cd freeradius-client-master
./configure --prefix=/
make
make install


FREERADIUSHOST="localhost"
FREERADIUSSECRET="testing123"

echo "172.17.0.3 testing123" >> /etc/radiusclient/servers

cat>/etc/radiusclient/dictionary.microsoft<<EOF
#
#       Microsoft's VSA's, from RFC 2548
#
#       \$Id: poptop_ads_howto_8.htm,v 1.8 2008/10/02 08:11:48 wskwok Exp \$
#
VENDOR          Microsoft       311     Microsoft
BEGIN VENDOR    Microsoft
ATTRIBUTE       MS-CHAP-Response        1       string  Microsoft
ATTRIBUTE       MS-CHAP-Error           2       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-1           3       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-2           4       string  Microsoft
ATTRIBUTE       MS-CHAP-LM-Enc-PW       5       string  Microsoft
ATTRIBUTE       MS-CHAP-NT-Enc-PW       6       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Policy 7     string  Microsoft
# This is referred to as both singular and plural in the RFC.
# Plural seems to make more sense.
ATTRIBUTE       MS-MPPE-Encryption-Type 8       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Types  8     string  Microsoft
ATTRIBUTE       MS-RAS-Vendor           9       integer Microsoft
ATTRIBUTE       MS-CHAP-Domain          10      string  Microsoft
ATTRIBUTE       MS-CHAP-Challenge       11      string  Microsoft
ATTRIBUTE       MS-CHAP-MPPE-Keys       12      string  Microsoft encrypt=1
ATTRIBUTE       MS-BAP-Usage            13      integer Microsoft
ATTRIBUTE       MS-Link-Utilization-Threshold 14 integer        Microsoft
ATTRIBUTE       MS-Link-Drop-Time-Limit 15      integer Microsoft
ATTRIBUTE       MS-MPPE-Send-Key        16      string  Microsoft
ATTRIBUTE       MS-MPPE-Recv-Key        17      string  Microsoft
ATTRIBUTE       MS-RAS-Version          18      string  Microsoft
ATTRIBUTE       MS-Old-ARAP-Password    19      string  Microsoft
ATTRIBUTE       MS-New-ARAP-Password    20      string  Microsoft
ATTRIBUTE       MS-ARAP-PW-Change-Reason 21     integer Microsoft
ATTRIBUTE       MS-Filter               22      string  Microsoft
ATTRIBUTE       MS-Acct-Auth-Type       23      integer Microsoft
ATTRIBUTE       MS-Acct-EAP-Type        24      integer Microsoft
ATTRIBUTE       MS-CHAP2-Response       25      string  Microsoft
ATTRIBUTE       MS-CHAP2-Success        26      string  Microsoft
ATTRIBUTE       MS-CHAP2-CPW            27      string  Microsoft
ATTRIBUTE       MS-Primary-DNS-Server   28      ipaddr
ATTRIBUTE       MS-Secondary-DNS-Server 29      ipaddr
ATTRIBUTE       MS-Primary-NBNS-Server  30      ipaddr Microsoft
ATTRIBUTE       MS-Secondary-NBNS-Server 31     ipaddr Microsoft
#ATTRIBUTE      MS-ARAP-Challenge       33      string  Microsoft
#
#       Integer Translations
#
#       MS-BAP-Usage Values
VALUE           MS-BAP-Usage            Not-Allowed     0
VALUE           MS-BAP-Usage            Allowed         1
VALUE           MS-BAP-Usage            Required        2
#       MS-ARAP-Password-Change-Reason Values
VALUE   MS-ARAP-PW-Change-Reason        Just-Change-Password            1
VALUE   MS-ARAP-PW-Change-Reason        Expired-Password                2
VALUE   MS-ARAP-PW-Change-Reason        Admin-Requires-Password-Change  3
VALUE   MS-ARAP-PW-Change-Reason        Password-Too-Short              4
#       MS-Acct-Auth-Type Values
VALUE           MS-Acct-Auth-Type       PAP             1
VALUE           MS-Acct-Auth-Type       CHAP            2
VALUE           MS-Acct-Auth-Type       MS-CHAP-1       3
VALUE           MS-Acct-Auth-Type       MS-CHAP-2       4
VALUE           MS-Acct-Auth-Type       EAP             5
#       MS-Acct-EAP-Type Values
VALUE           MS-Acct-EAP-Type        MD5             4
VALUE           MS-Acct-EAP-Type        OTP             5
VALUE           MS-Acct-EAP-Type        Generic-Token-Card      6
VALUE           MS-Acct-EAP-Type        TLS             13
END-VENDOR Microsoft
EOF

sed -i -e "/dictionary.merit/d" -e "/dictionary.microsoft/d" -e "/-Traffic/d" /etc/radiusclient/dictionary

cat>>/etc/radiusclient/dictionary<<EOF
INCLUDE /etc/radiusclient/dictionary.merit
INCLUDE /etc/radiusclient/dictionary.microsoft
EOF

cat>/etc/radiusclient/radiusclient.conf<<EOF
# General settings
# specify which authentication comes first respectively which
# authentication is used. possible values are: "radius" and "local".
# if you specify "radius,local" then the RADIUS server is asked
# first then the local one. if only one keyword is specified only
# this server is asked.
auth_order	radius,local
# maximum login tries a user has
login_tries	4
# timeout for all login tries
# if this time is exceeded the user is kicked out
login_timeout	60
# name of the nologin file which when it exists disables logins. it may 
# be extended by the ttyname which will result in 
#a terminal specific lock (e.g. /etc/nologin.ttyS2 will disable
# logins on /dev/ttyS2)
nologin /etc/nologin
# name of the issue file. it's only display when no username is passed
# on the radlogin command line
issue	/etc/radiusclient/issue
seqfile /var/run/freeradius/freeradius.pid
## RADIUS listens separated by a colon from the hostname. if
# no port is specified /etc/services is consulted of the radius
authserver 	localhost
# RADIUS server to use for accouting requests. All that I
# said for authserver applies, too.
acctserver 	localhost
# file holding shared secrets used for the communication
# between the RADIUS client and server
servers		/etc/radiusclient/servers
# dictionary of allowed attributes and values just like in the normal 
# RADIUS distributions
dictionary 	/etc/radiusclient/dictionary
# program to call for a RADIUS authenticated login
login_radius	/sbin/login.radius
# file which specifies mapping between ttyname and NAS-Port attribute
mapfile		/etc/radiusclient/port-id-map
# default authentication realm to append to all usernames if no
# realm was explicitly specified by the user
default_realm
# time to wait for a reply from the RADIUS server
radius_timeout	10
# resend request this many times before trying the next server
radius_retries	3
#radius_deadtime	0
# local address from which radius packets have to be sent
bindaddr *
# program to execute for local login
# it must support the -f flag for preauthenticated login
login_local	/bin/login
EOF



sed -i "s/ATTRIBUTE\tNAS-IPv6-Address\t95\tstring/#ATTRIBUTE\tNAS-IPv6-Address\t95\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tFramed-Interface-Id\t96\tstring/#ATTRIBUTE\tFramed-Interface-Id\t96\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tFramed-IPv6-Prefix\t97\tipv6prefix/#ATTRIBUTE\tFramed-IPv6-Prefix\t97\tipv6prefix/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tLogin-IPv6-Host\t98\tstring/#ATTRIBUTE\tLogin-IPv6-Host\t98\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tFramed-IPv6-Route\t99\tstring/#ATTRIBUTE\tFramed-IPv6-Route\t99\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tFramed-IPv6-Pool\t100\tstring/#ATTRIBUTE\tFramed-IPv6-Pool\t100\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tError-Cause\t101\tinteger/#ATTRIBUTE\tError-Cause\t101\tinteger/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tEAP-Key-Name\t102\tstring/#ATTRIBUTE\tEAP-Key-Name\t102\tstring/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tFramed-IPv6-Address\t168\tipv6addr/#ATTRIBUTE\tFramed-IPv6-Address\t168\tipv6addr/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tDNS-Server-IPv6-Address\t169\tipv6addr/#ATTRIBUTE\tDNS-Server-IPv6-Address\t169\tipv6addr/g"  /etc/radiusclient/dictionary
sed -i "s/ATTRIBUTE\tRoute-IPv6-Information\t170\tipv6prefix/#ATTRIBUTE\tRoute-IPv6-Information\t170\tipv6prefix/g"  /etc/radiusclient/dictionary

