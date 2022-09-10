#!/bin/bash

# Getting
MYIP=$(wget -qO- ipinfo.io/ip);
domain=$(cat /usr/local/etc/xray/domain)
tls="$(cat ~/log-install.txt | grep -w "Vmess TLS" | cut -d: -f2|sed 's/ //g')"
nontls="$(cat ~/log-install.txt | grep -w "Vmess None TLS" | cut -d: -f2|sed 's/ //g')"
grpc="$(cat ~/log-install.txt | grep -w "Vmess gRPC" | cut -d: -f2|sed 's/ //g')"
sed -i '/#xray-vmess-tls$/a\#vmtls# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1@${domain}""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vmess-nontls$/a\#vmnone# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1@${domain}""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vmess-grpc$/a\#vmgrpc# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1@${domain}""'"' /usr/local/etc/xray/config.json
echo -e "${1}\t${3}\t${2}" >> /usr/local/etc/xray/vmess.conf
cat>/usr/local/etc/xray/vmess-$1-tls.json<<EOF
{
      "v": "2",
      "ps": "GETTUNEL.COM-${1}-TLS",
      "add": "${domain}",
      "port": "${tls}",
      "id": "${3}",
      "aid": "0",
      "net": "ws",
      "path": "/gettunel-vmess-tls",
      "type": "none",
      "host": "${domain}",
      "tls": "tls"
}
EOF
cat>/usr/local/etc/xray/vmess-$1-none.json<<EOF
{
      "v": "2",
      "ps": "GETTUNEL.COM-${1}-none",
      "add": "${domain}",
      "port": "${nontls}",
      "id": "${3}",
      "aid": "0",
      "net": "ws",
      "path": "/gettunel-vmess-none",
      "type": "none",
      "host": "${domain}",
      "tls": "none"
}
EOF
cat>/usr/local/etc/xray/vmess-$1-grpc.json<<EOF
      {
      "v": "2",
      "ps": "GETTUNEL.COM-${1}-gRPC",
      "add": "${domain}",
      "port": "${grpc}",
      "aid": "0",
      "type": "gun",
      "net": "grpc",
      "path": "gettunel-vmess-grpc",
      "host": "${domain}",
      "id": "${3}",
      "tls": "tls"
}
EOF
systemctl restart xray.service
systemctl restart xray@none.service
service cron restart
