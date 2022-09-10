#!/bin/bash

#AutoScript by Gugun
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
# ==========================================
# Getting
MYIP=$(wget -qO- ipinfo.io/ip);
clear
domain=$(cat /usr/local/etc/xray/domain)
tls="$(cat ~/log-install.txt | grep -w "Vmess TLS" | cut -d: -f2|sed 's/ //g')"
nontls="$(cat ~/log-install.txt | grep -w "Vmess None TLS" | cut -d: -f2|sed 's/ //g')"
grpc="$(cat ~/log-install.txt | grep -w "Vmess gRPC" | cut -d: -f2|sed 's/ //g')"
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    read -rp "Username : " -e user
    CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)

    if [[ ${CLIENT_EXISTS} == '1' ]]; then
         echo ""
         echo -e "Username ${RED}${CLIENT_NAME}${NC} Already On VPS Please Choose Another"
         exit 1
   fi
done
email=${user}@${domain}
uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Expired (Days) : " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
sed -i '/#xray-vmess-tls$/a\#vmtls# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vmess-nontls$/a\#vmnone# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vmess-grpc$/a\#vmgrpc# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/config.json
echo -e "${user}\t${uuid}\t${exp}" >> /usr/local/etc/xray/vmess.conf
cat>/usr/local/etc/xray/vmess-$user-tls.json<<EOF
{
      "v": "2",
      "ps": "GETTUNEL.COM-${user}-TLS",
      "add": "${domain}",
      "port": "${tls}",
      "id": "${uuid}",
      "aid": "0",
      "net": "ws",
      "path": "/gettunel-vmess-tls",
      "type": "none",
      "host": "",
      "tls": "tls"
}
EOF
cat>/usr/local/etc/xray/vmess-$user-none.json<<EOF
{
      "v": "2",
      "ps": "GETTUNEL.COM-${user}-none",
      "add": "${domain}",
      "port": "${nontls}",
      "id": "${uuid}",
      "aid": "0",
      "net": "ws",
      "path": "/gettunel-vmess-none",
      "type": "none",
      "host": "",
      "tls": "none"
}
EOF
cat>/usr/local/etc/xray/vmess-$user-grpc.json<<EOF
      {
      "v": "2",
      "ps": "GETTUNEL.COM-${user}-gRPC",
      "add": "${domain}",
      "port": "${grpc}",
      "aid": "0",
      "type": "gun",
      "net": "grpc",
      "path": "gettunel-vmess-grpc",
      "host": "",
      "id": "${uuid}",
      "tls": "tls"
}
EOF
vmess_base641=$( base64 -w 0 <<< $vmess_json1)
vmess_base642=$( base64 -w 0 <<< $vmess_json2)
vmess_base643=$( base64 -w 0 <<< $vmess_json3)
xrayv2ray1="vmess://$(base64 -w 0 /usr/local/etc/xray/vmess-$user-tls.json)"
xrayv2ray2="vmess://$(base64 -w 0 /usr/local/etc/xray/vmess-$user-none.json)"
xraygrpc="vmess://$(base64 -w 0 /usr/local/etc/xray/vmess-$user-grpc.json)"
systemctl restart xray.service
systemctl restart xray@none.service
service cron restart
clear
echo -e ""
echo -e "======-XRAYS/VMESS-======"
echo -e "Remarks     : ${user}"
echo -e "IP/Host     : ${MYIP}"
echo -e "Address     : ${domain}"
echo -e "Port TLS    : ${tls}"
echo -e "Port No TLS : ${nontls}"
echo -e "Port gRPC   : ${grpc}"
echo -e "User ID     : ${uuid}"
echo -e "Alter ID    : 0"
echo -e "Security    : auto"
echo -e "Network     : ws"
echo -e "Path TLS    : /gettunel-vmess-tls"
echo -e "Path None   : /gettunel-vmess-none"
echo -e "serviceName : gettunel-vmeess-grpc"
echo -e "Expired     : $exp"
echo -e "========================="
echo -e "Link TLS    : ${xrayv2ray1}"
echo -e "========================="
echo -e "Link No TLS : ${xrayv2ray2}"
echo -e "========================="
echo -e "Link gRPC   : ${xraygrpc}"
echo -e "========================="
