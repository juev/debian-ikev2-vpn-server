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
SHARED_SECRET="$(openssl rand -base64 64 2>/dev/null)"
[ -f /etc/ipsec.secrets ] || echo ": PSK \"${SHARED_SECRET}\"" > /etc/ipsec.secrets

./bin/generate-mobileconfig > ~/ikev2-vpn.mobileconfig

systemctl restart ipsec
