#!/bin/bash

# MIT License
# 
# Copyright (c) 2016 Evsyukov Denis
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if [ "$EUID" -ne 0 ]
then echo "Please run as root"
  exit
fi

[ -f "/etc/apt/sources.list.d/jessie.list" ] && rm /etc/apt/sources.list.d/jessie.list
echo "deb http://ftp.debian.org/debian jessie-backports main contrib" >> /etc/apt/sources.list.d/jessie.list
echo "deb http://ftp.debian.org/debian sid main contrib" >> /etc/apt/sources.list.d/jessie.list

cp ./etc/apt/preferences.d/ndppd /etc/apt/preferences.d/

aptitude update \
  && DEBIAN_FRONTEND=noninteractive aptitude -y upgrade \
  && DEBIAN_FRONTEND=noninteractive aptitude -y install iptables uuid-runtime openssl openntpd \
  && DEBIAN_FRONTEND=noninteractive aptitude -y -t jessie-backports install strongswan \
  && DEBIAN_FRONTEND=noninteractive aptitude -y -t unstable install ndppd

rm /etc/ipsec.secrets

cp ./etc/* /etc/

sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sed -i '/^#net.ipv6.conf.all.forwarding=1/s/^#//' /etc/sysctl.conf
grep -q 'net.ipv6.conf.eth0.proxy_ndp=1' /etc/sysctl.conf || echo 'net.ipv6.conf.eth0.proxy_ndp=1' >> /etc/sysctl.conf

sysctl -f

./bin/iptables
iptables-save > /etc/firewall.conf
cat <<EOF > /etc/network/if-up.d/iptables
#!/bin/sh
iptables-restore < /etc/firewall.conf
EOF
chmod +x /etc/network/if-up.d/iptables

# hotfix for openssl `unable to write 'random state'` stderr
SHARED_SECRET="123$(openssl rand -base64 32 2>/dev/null)qwe"
[ -f /etc/ipsec.secrets ] || echo ": PSK \"${SHARED_SECRET}\"" > /etc/ipsec.secrets

./bin/generate-mobileconfig > ~/ikev2-vpn.mobileconfig

systemctl restart ndppd
systemctl restart ipsec
