#!/bin/bash
data=( `cat /usr/local/etc/xray/config.json | grep '^#vmtls#' | cut -d ' ' -f 2`);
now=`date +"%Y-%m-%d"`
for user in "${data[@]}"
do
exp=$(grep -w "^#vmtls# $user" "/usr/local/etc/xray/config.json" | cut -d ' ' -f 3)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
if [[ "$exp2" = "0" ]]; then
sed -i "/^#vmtls# $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
sed -i "/^#vmnone# $user $exp/,/^},{/d" /usr/local/etc/xray/none.json
sed -i "/^#vmgrpc# $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
sed -i "/\b$user\b/d" /usr/local/etc/xray/vmess.conf
rm -f /usr/local/etc/xray/vmess-$user-tls.json /usr/local/etc/xray/vmess-$user-none.json /usr/local/etc/xray/vmess-$user-grpc.json
fi
done
systemctl restart xray.service
systemctl restart xray@none.service
