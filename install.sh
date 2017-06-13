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

if ! type aptitude > /dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get -y install aptitude 
fi

aptitude update \
  && DEBIAN_FRONTEND=noninteractive aptitude -y upgrade \
  && DEBIAN_FRONTEND=noninteractive aptitude -y install iptables uuid-runtime openssl openntpd \
  && DEBIAN_FRONTEND=noninteractive aptitude -y install strongswan

rm /etc/ipsec.secrets

cp -R ./etc/* /etc/

sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf

sysctl -f

./bin/iptables
iptables-save > /etc/firewall.conf
cat <<EOF > /etc/network/if-up.d/iptables
#!/bin/sh
iptables-restore < /etc/firewall.conf
EOF
chmod +x /etc/network/if-up.d/iptables

# hotfix for openssl `unable to write 'random state'` stderr
SHARED_SECRET="$(openssl rand -base64 32 2>/dev/null)"
[ -f /etc/ipsec.secrets ] || echo ": PSK \"${SHARED_SECRET}\"" > /etc/ipsec.secrets

./bin/generate-mobileconfig > ~/ikev2-vpn.mobileconfig

if ! grep -qs "hwdsl2 VPN script" /etc/sysctl.conf; then
cat >> /etc/sysctl.conf <<EOF
# Added by hwdsl2 VPN script
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.$NET_IFACE.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.conf.$NET_IFACE.rp_filter = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF
fi

systemctl restart ipsec
