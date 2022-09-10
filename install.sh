#!/bin/bash

#AutoScript by Gugun

wget -O /root/domain "https://raw.githubusercontent.com/pixiqdarkit/xray/main/domain" && chmod +x domain

apt update && apt upgrade -y && update-grub && sleep 2 && apt-get update -y && apt-get upgrade && sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl unzip

domain=$(cat /root/domain)
MYIP="s/xxxxxxxx/$domain/g";
apt install iptables iptables-persistent -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
timedatectl set-ntp true
systemctl enable chronyd && systemctl restart chronyd
systemctl enable chrony && systemctl restart chrony
timedatectl set-timezone Asia/Jakarta
chronyc sourcestats -v
chronyc tracking -v
date

source /etc/os-release
OS=$ID
ver=$VERSION_ID

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo -e "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

mkdir -p /etc/xray

apt install -y socat
cd /root/
wget https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh
bash acme.sh --install
rm acme.sh
cd .acme.sh
bash acme.sh --register-account -m gratisan009@gmail.com
bash acme.sh --issue --standalone -d $domain --force
bash acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key
cd
chown -R nobody:nogroup /etc/xray/
# Install Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Install nginx Debian / Ubuntu
if [[ $OS == 'debian' ]]; then
	apt install -y gnupg2 ca-certificates lsb-release debian-archive-keyring && curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg && printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list && printf "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900" > /etc/apt/preferences.d/99nginx && apt update -y && apt install -y nginx && mkdir -p /etc/systemd/system/nginx.service.d && printf "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf
elif [[ $OS == 'ubuntu' ]]; then
	apt install -y gnupg2 ca-certificates lsb-release ubuntu-keyring && curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg && printf "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list && printf "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900" > /etc/apt/preferences.d/99nginx && apt update -y && apt install -y nginx && mkdir -p /etc/systemd/system/nginx.service.d && printf "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf
fi

curl -Lo /etc/nginx/nginx.conf https://gitlab.com/wid09/nginx/raw/main/nginx.conf
sed -i $MYIP /etc/nginx/nginx.conf

uuid=$(cat /proc/sys/kernel/random/uuid)
cat> /usr/local/etc/xray/config.json << END
{
  "log": {
    "loglevel": "warning",
    "error": "/var/log/xray/error.log", 
    "access": "/var/log/xray/access.log" 
  },
  "inbounds": [
    {
      "listen": "127.0.0.1", 
      "port": 2009, 
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}", 
            "email": "2009@gmail.com"
#xray-vmess-grpc
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "gun",
        "security": "none",
        "grpcSettings": {
          "serviceName": "gettunel-vmess-grpc" 
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 2001,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}", 
            "email": "2001@gmail.com"
#xray-vmess-tls
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/gettunel-vmess-tls" 
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
	{
      "listen": "127.0.0.1", 
      "port": 2002,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}", 
            "email": "2002@gmail.com"
#xray-vless-tls
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/gettunel-vless-tls"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
	{
      "listen": "127.0.0.1", 
      "port": 2010, 
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}", 
            "email": "2009@gmail.com"
#xray-vless-grpc
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "gun",
        "security": "none",
        "grpcSettings": {
          "serviceName": "gettunel-vless-grpc" 
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  }
}
END
# None
cat> /usr/local/etc/xray/none.json << END
{
  "log": {
    "loglevel": "warning",
    "error": "/var/log/xray/error.log", 
    "access": "/var/log/xray/access.log" 
  },
  "inbounds": [
     {
      "port": 80, 
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "21376258-dd56-11e9-aa37-5600024c1d6a", 
            "email": "2001@gmail.com"
#xray-vmess-nontls
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/gettunel-vmess-none"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "port": 80, 
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "21376258-dd56-11e9-aa37-5600024c1d6a",
            "email": "2001@gmail.com"
#xray-vless-nontls
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/gettunel-vless-none"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  }
}
END
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

systemctl daemon-reload
systemctl restart nginx
systemctl enable xray
systemctl start xray
systemctl enable xray@none.service
systemctl start xray@none.service

#List Akun Vmess
touch /usr/local/etc/xray/vmess.conf
touch /usr/local/etc/xray/vless.conf

# Install fail2ban
apt install -y fail2ban
service fail2ban restart

# Install DDoS Deflate
cd
apt install -y dnsutils tcpdump dsniff grepcidr
wget -qO ddos.zip "https://raw.githubusercontent.com/iriszz-official/autoscript/main/FILES/ddos-deflate.zip"
unzip ddos.zip
cd ddos-deflate
chmod +x install.sh
./install.sh
cd
rm -rf ddos.zip ddos-deflate

# Download Menu
cd /usr/bin
wget -O addws "https://raw.githubusercontent.com/pixiqdarkit/xray/main/addws.sh" && chmod +x addws
wget -O addvless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/addvless.sh" && chmod +x addvless
wget -O cekws "https://raw.githubusercontent.com/pixiqdarkit/xray/main/cekws.sh" && chmod +x cekws
wget -O dellws "https://raw.githubusercontent.com/pixiqdarkit/xray/main/dellws.sh" && chmod +x dellws
wget -O dellvless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/dellvless.sh" && chmod +x dellvless
wget -O vmess "https://raw.githubusercontent.com/pixiqdarkit/xray/main/vmess.sh" && chmod +x vmess
wget -O vless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/vless.sh" && chmod +x vless
wget -O xp-ws "https://raw.githubusercontent.com/pixiqdarkit/xray/main/xp-ws.sh" && chmod +x xp-ws
wget -O xp-vless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/xp-vless.sh" && chmod +x xp-vless
# Untuk panel ssh
wget -O renewVmess "https://raw.githubusercontent.com/pixiqdarkit/xray/main/renewVmess.sh" && chmod +x renewVmess
wget -O renewVless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/renewVless.sh" && chmod +x renewVless
wget -O forceDeleteVmess "https://raw.githubusercontent.com/pixiqdarkit/xray/main/forceDeleteVmess.sh" && chmod +x forceDeleteVmess
wget -O forceDeleteVless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/forceDeleteVless.sh" && chmod +x forceDeleteVless
wget -O reGenerateVmess "https://raw.githubusercontent.com/pixiqdarkit/xray/main/reGenerateVmess.sh" && chmod +x reGenerateVmess
wget -O reGenerateVless "https://raw.githubusercontent.com/pixiqdarkit/xray/main/reGenerateVless.sh" && chmod +x reGenerateVless

cd
echo "0 4 * * * root reboot" >> /etc/crontab
echo "0 0 * * * root xp-ws" >> /etc/crontab
echo "0 0 * * * root xp-vless" >> /etc/crontab

wget https://gitlab.com/wid09/multi-trojan-xray/-/raw/main/set-br.sh && chmod +x set-br.sh && sed -i -e 's/\r$//' set-br.sh && ./set-br.sh && rm -f /root/set-br.sh
wget https://raw.githubusercontent.com/pixiqdarkit/xray/main/bbr.sh && chmod +x bbr.sh && ./bbr.sh
cp domain /usr/local/etc/xray/
echo "==================================="  | tee -a log-install.txt
echo "====AutoScript XRay VMess/VLess===="  | tee -a log-install.txt
echo "              Gugun09              "
echo "==================================="  | tee -a log-install.txt
echo "   - XRAYS Vmess TLS         : 443 "  | tee -a log-install.txt
echo "   - XRAYS Vmess None TLS    : 80  "  | tee -a log-install.txt
echo "   - XRAYS Vmess gRPC        : 443 "  | tee -a log-install.txt
echo "==================================="  | tee -a log-install.txt
echo "   - XRAYS Vless TLS         : 443 "  | tee -a log-install.txt
echo "   - XRAYS Vless None TLS    : 80  "  | tee -a log-install.txt
echo "   - XRAYS Vless gRPC        : 443 "  | tee -a log-install.txt
echo "==================================="  | tee -a log-install.txt

rm -f /root/setup.sh
history -c
reboot
