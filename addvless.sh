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
tls="$(cat ~/log-install.txt | grep -w "Vless TLS" | cut -d: -f2|sed 's/ //g')"
nontls="$(cat ~/log-install.txt | grep -w "Vless None TLS" | cut -d: -f2|sed 's/ //g')"
grpc="$(cat ~/log-install.txt | grep -w "Vless gRPC" | cut -d: -f2|sed 's/ //g')"
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
sed -i '/#xray-vless-tls$/a\#vltls# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-nontls$/a\#vlnone# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-grpc$/a\#vlgrpc# '"$user $exp"'\
},{"id": "'""$uuid""'","level": '"0"',"email": "'""$email""'"' /usr/local/etc/xray/config.json
echo -e "${user}\t${uuid}\t${exp}" >> /usr/local/etc/xray/vless.conf
vlesslink1="vless://${uuid}@${domain}:$tls?path=/gettunel-vless-tls&security=tls&encryption=none&type=ws#GETTUNEL.COM+${user}+TLS"
vlesslink2="vless://${uuid}@${domain}:$none?path=/gettunel-vless-none&encryption=none&type=ws#GETTUNEL.COM+${user}+none"
vlesslink3="vless://${uuid}@${domain}:${grpc}?encryption=none&security=tls&type=grpc&serviceName=gettunel-vless-grpc&mode=gun#GETTUNEL.COM+${user}+gRPC"
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
echo -e "Encryption  : none"
echo -e "Network     : ws"
echo -e "Path TLS    : /gettunel-vless-tls"
echo -e "Path None   : /gettunel-vless-none"
echo -e "serviceName : gettunel-vless-grpc"
echo -e "Expired     : $exp"
echo -e "========================="
echo -e "Link TLS    : ${vlesslink1}"
echo -e "========================="
echo -e "Link No TLS : ${vlesslink2}"
echo -e "========================="
echo -e "Link gRPC   : ${vlesslink3}"
echo -e "========================="
