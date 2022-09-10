#!/bin/bash

#AutoScript by Gugun
# ==========================================
# Getting
MYIP=$(wget -qO- ipinfo.io/ip);
domain=$(cat /usr/local/etc/xray/domain)
tls="$(cat ~/log-install.txt | grep -w "Vless TLS" | cut -d: -f2|sed 's/ //g')"
nontls="$(cat ~/log-install.txt | grep -w "Vless None TLS" | cut -d: -f2|sed 's/ //g')"
grpc="$(cat ~/log-install.txt | grep -w "Vless gRPC" | cut -d: -f2|sed 's/ //g')"

#uuid=$(cat /proc/sys/kernel/random/uuid)
sed -i '/#xray-vless-tls$/a\#vltls# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-nontls$/a\#vlnone# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-grpc$/a\#vlgrpc# '"$1 $2"'\
},{"id": "'""$3""'","level": '"0"',"email": "'""$1""'"' /usr/local/etc/xray/config.json
echo -e "${1}\t${3}\t${2}" >> /usr/local/etc/xray/vless.conf
systemctl restart xray.service
systemctl restart xray@none.service
service cron restart

