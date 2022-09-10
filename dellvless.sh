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
NUMBER_OF_CLIENTS=$(grep -c -E "^#vltls# " "/usr/local/etc/xray/config.json")
	if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
		echo ""
		echo "You have no existing clients!"
		exit 1
	fi

	clear
	echo ""
	echo " Select the existing client you want to remove"
	echo " Press CTRL+C to return"
	echo " ==============================="
	echo "     No  Expired   User"
	grep -E "^#vltls# " "/usr/local/etc/xray/config.json" | cut -d ' ' -f 2-3 | nl -s ') '
	until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
		if [[ ${CLIENT_NUMBER} == '1' ]]; then
			read -rp "Select one client [1]: " CLIENT_NUMBER
		else
			read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
		fi
	done
user=$(grep -E "^#vltls# " "/usr/local/etc/xray/config.json" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^#vltls# " "/usr/local/etc/xray/config.json" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
sed -i "/^#vltls# $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
sed -i "/^#vlnone# $user $exp/,/^},{/d" /usr/local/etc/xray/none.json
sed -i "/^#vlgrpc# $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
sed -i "/\b$user\b/d" /usr/local/etc/xray/vless.conf
systemctl restart xray.service
systemctl restart xray@none.service
service cron restart
clear
echo ""
echo "==============================="
echo "  XRAYS/Vless Account Deleted  "
echo "==============================="
echo "Username  : $user"
echo "Expired   : $exp"
echo "==============================="
