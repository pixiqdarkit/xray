#!/bin/bash

function add-user() {
	clear
	echo -e "Add Xray User"
	echo -e "-------------"
	read -p "Username : " user
	if grep -qw "$user" /usr/local/etc/xray/akun.conf; then
		echo -e ""
		echo -e "User '$user' already exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " duration

	uuid=$(uuidgen)
	exp=$(date -d +${duration}days +%Y-%m-%d)
	expired=$(date -d "${exp}" +"%d %b %Y")
	domain=$(cat /usr/local/etc/xray/domain)
	email=${user}@${domain}
	echo -e "${user}\t${uuid}\t${exp}" >> /usr/local/etc/xray/akun.conf

	cat /usr/local/etc/xray/config.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	cat /usr/local/etc/xray/config.json | jq '.inbounds[1].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
    cat /usr/local/etc/xray/none.json | jq '.inbounds[0].settings.clients += [{"id": "'${uuid}'","email": "'${email}'"}]' > /usr/local/etc/xray/none_tmp.json
	mv -f /usr/local/etc/xray/none_tmp.json /usr/local/etc/xray/none.json
	service xray restart
    systemctl restart xray@none.service

	clear
	echo -e "Xray User Information"
	echo -e "---------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $expired"
	echo -e ""
}

function delete-user() {
	clear
	echo -e "Delete Xray User"
	echo -e "----------------"
	read -p "Username : " user
	echo -e ""
	if ! grep -qw "$user" /usr/local/etc/xray/akun.conf; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid="$(cat /usr/local/etc/xray/akun.conf | grep -w "$user" | awk '{print $2}')"

	cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[1].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
    cat /usr/local/etc/xray/none.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${uuid}'"))' > /usr/local/etc/xray/none_tmp.json
    mv -f /usr/local/etc/xray/none_tmp.json /usr/local/etc/xray/none.json
	sed -i "/\b$user\b/d" /usr/local/etc/xray/akun.conf
	service xray restart
    systemctl restart xray@none.service

	echo -e "User '$user' deleted successfully."
	echo -e ""
}

function extend-user() {
	clear
	echo -e "Extend Xray User"
	echo -e "----------------"
	read -p "Username : " user
	if ! grep -qw "$user" /usr/local/etc/xray/akun.conf; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " extend

	uuid=$(cat /usr/local/etc/xray/akun.conf | grep -w $user | awk '{print $2}')
	exp_old=$(cat /usr/local/etc/xray/akun.conf | grep -w $user | awk '{print $3}')
	diff=$((($(date -d "${exp_old}" +%s)-$(date +%s))/(86400)))
	duration=$(expr $diff + $extend + 1)
	exp_new=$(date -d +${duration}days +%Y-%m-%d)
	exp=$(date -d "${exp_new}" +"%d %b %Y")

	sed -i "/\b$user\b/d" /usr/local/etc/xray/akun.conf
	echo -e "$user\t$uuid\t$exp_new" >> /usr/local/etc/xray/akun.conf

	clear
	echo -e "Xray User Information"
	echo -e "---------------------"
	echo -e "Username : $user"
	echo -e "Expired date : $exp"
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired
	do
		user=$(echo $expired | awk '{print $1}')
		exp=$(echo $expired | awk '{print $3}')
		exp_date=$(date -d"${exp}" "+%d %b %Y")
		printf "%-17s %2s\n" "$user" "$exp_date"
	done < /usr/local/etc/xray/akun.conf
	total=$(wc -l /usr/local/etc/xray/akun.conf | awk '{print $1}')
	echo -e "-------------------------------"
	echo -e "Total accounts: $total"
	echo -e "==============================="
	echo -e ""
}

function user-monitor() {
	data=($(cat /usr/local/etc/xray/akun.conf | awk '{print $1}'))
	data2=($(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | grep -w 443 | awk '{print $5}' | cut -d: -f1 | sort | uniq))
	domain=$(cat /usr/local/etc/xray/domain)
	clear
	echo -e ""
	echo -e "========================="
	echo -e "   Xray Login Monitor"
	echo -e "-------------------------"
	for user in "${data[@]}"
	do
		touch /tmp/ipxray.txt
		for ip in "${data2[@]}"
		do
			total=$(cat /var/log/xray/access.log | grep -w ${user}@${domain} | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq)
			if [[ "$total" == "$ip" ]]; then
				echo -e "$total" >> /tmp/ipxray.txt
			fi
		done
		total=$(cat /tmp/ipxray.txt)
		if [[ -n "$total" ]]; then
			total2=$(cat /tmp/ipxray.txt | nl)
			echo -e "$user :"
			echo -e "$total2"
		fi
		rm -f /tmp/ipxray.txt
	done
	echo -e "========================="
	echo -e ""
}

function user-monitor() {
	data=($(cat /usr/local/etc/xray/akun.conf | awk '{print $1}'))
	data2=($(netstat -anp | grep ESTABLISHED | grep tcp6 | grep xray | grep -w 443 | awk '{print $5}' | cut -d: -f1 | sort | uniq))
	domain=$(cat /usr/local/etc/xray/domain)
	clear
	echo -e ""
	echo -e "========================="
	echo -e "  Xray Login Monitor"
	echo -e "-------------------------"
	for user in "${data[@]}"
	do
		for ip in "${data2[@]}"
		do
			total=$(cat /var/log/xray/access.log | grep -w ${user}@${domain} | awk '{print $3}' | cut -d: -f1 | grep -w $ip | sort | uniq)
			if [[ "$total" == "$ip" ]]; then
				echo -e "$total" >> /tmp/ipxray.txt
			fi
		done
		total=$(cat /tmp/ipxray.txt)
		if [[ -n "$total" ]]; then
			total2=$(cat /tmp/ipxray.txt | nl)
			echo -e "$user :"
			echo -e "$total2"
		fi
		rm -f /tmp/ipxray.txt
	done
	echo -e "========================="
	echo -e ""
	rm -f /tmp/ipxray.txt
}

function show-config() {
	echo -e "Xray Config"
	echo -e "-----------"
	read -p "User : " user
	if ! grep -qw "$user" /usr/local/etc/xray/akun.conf; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	uuid=$(cat /usr/local/etc/xray/akun.conf | grep -w "$user" | awk '{print $2}')
	domain=$(cat /usr/local/etc/xray/domain)
	exp=$(cat /usr/local/etc/xray/akun.conf | grep -w "$user" | awk '{print $3}')
	exp_date=$(date -d"${exp}" "+%d %b %Y")

	echo -e "Expired : $exp_date"
	echo -e ""
	echo -e "VLESS + WebSocket + TLS"
	echo -e "-----------------------"
	echo -e "Host : $domain"
	echo -e "Server Port : 443"
	echo -e "User ID : $uuid"
	echo -e "Security : none"
	echo -e "Network Type : ws"
	echo -e "WebSocket Path : /xray"
	echo -e "TLS : tls"
	echo -e ""
	echo -e "Link : vless://$uuid@$domain:443?type=ws&encryption=none&security=tls&path=%2fxray#XRAY_WS_TLS-$user"
	echo -e ""
	echo -e "QR : https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$uuid@$domain:443?type=ws%26encryption=none%26security=tls%26path=%2fxray%23XRAY_WS_TLS-$user"
	echo -e ""
	echo -e "VLESS + TLS / XTLS"
	echo -e "------------------"
	echo -e "Adress: $domain"
	echo -e "Port: 443"
	echo -e "ID: $uuid"
	echo -e "Encryption: none"
	echo -e "Network: tcp"
	echo -e "Header Type: none"
	echo -e "TLS: tls / xtls"
	echo -e ""
	echo -e "Link : vless://$uuid@$domain:443?security=xtls&encryption=none&flow=xtls-rprx-direct#XRAY_XTLS-$user"
	echo -e ""
	echo -e "QR : https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$uuid@$domain:443?security=xtls%26encryption=none%26flow=xtls-rprx-direct%23XRAY_XTLS-$user"
	echo -e ""
}

clear
echo -e "==========[ Xray Menu ]=========="
echo -e ""
echo -e "  [1] Add Xray user"
echo -e "  [2] Delete Xray user"
echo -e "  [3] Extend Xray user"
echo -e "  [4] Xray user list"
echo -e "  [5] Xray user monitor"
echo -e "  [6] Show Xray configuration"
echo -e "  [7] Exit"
echo -e ""
until [[ ${option} =~ ^[1-7]$ ]]; do
	read -rp "Select an option [1-7]: " option
done
case "${option}" in
1)
	add-user
	;;
2)
	delete-user
	;;
3)
	extend-user
	;;
4)
	user-list
	;;
5)
	user-monitor
	;;
6)
	clear
	show-config
	;;
7)
	clear
	exit 0
	;;
esac
