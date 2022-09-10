# nginx

# Auto Script XRay VMess VLess

apt-get update && apt-get upgrade -y && update-grub && sleep 2 && reboot

rm -f setup.sh && apt update && apt upgrade -y && update-grub && sleep 2 && apt-get update -y && apt-get upgrade && sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl unzip && wget -O setup.sh https://raw.githubusercontent.com/pixiqdarkit/xray/main/install.sh && chmod +x setup.sh && sed -i -e 's/\r$//' setup.sh && screen -S setup ./setup.sh
