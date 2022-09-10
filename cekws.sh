#!/bin/bash

#AutoScript by Gugun
# ==========================================
data=($(cat /usr/local/etc/xray/vmess.conf | awk '{print $1}'))
	data2=($(netstat -anp | grep ESTABLISHED | grep tcp | grep xray | grep -w 443 | awk '{print $5}' | cut -d: -f1 | sort | uniq))
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
