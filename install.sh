#!/bin/bash

set -e

echo -e "\033[1;32m==== Script SSH + Proxy + WebSocket + UDP por ebx ====\033[0m"
echo "Actualizando sistema y paquetes base..."
apt update && apt upgrade -y
apt install -y sudo curl wget ufw iptables nano unzip git

echo -e "\n\033[1;34m--- Instalando OpenSSH (por defecto en Ubuntu) ---\033[0m"
apt install -y openssh-server

echo -e "\n\033[1;34m--- Instalando Dropbear ---\033[0m"
apt install -y dropbear
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=110/' /etc/default/dropbear
echo "DROPBEAR_EXTRA_ARGS=\"-p 443 -p 222\"" >> /etc/default/dropbear
systemctl enable dropbear && systemctl restart dropbear

echo -e "\n\033[1;34m--- Instalando Squid Proxy ---\033[0m"
apt install -y squid
cp squid.conf /etc/squid/squid.conf || wget -O /etc/squid/squid.conf https://raw.githubusercontent.com/roosterkid/openproxylist/main/squid/squid.conf
systemctl enable squid && systemctl restart squid

echo -e "\n\033[1;34m--- Instalando WebSocket SSH Proxy (modo relax) ---\033[0m"
apt install -y nodejs npm
mkdir -p /opt/wsproxy
cp ws-relax.js /opt/wsproxy/ws-relax.js
cd /opt/wsproxy
npm install
ufw allow 80/tcp
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
systemctl stop apache2 2>/dev/null || true
nohup node ws-relax.js > /dev/null 2>&1 &

echo -e "\n\033[1;34m--- Instalando BADVPN UDPGW ---\033[0m"
wget -O /usr/bin/badvpn-udpgw https://github.com/ambrop72/badvpn/releases/download/v1.999.130/badvpn-udpgw
chmod +x /usr/bin/badvpn-udpgw
nohup badvpn-udpgw --listen-addr 127.0.0.1:7300 > /dev/null 2>&1 &

echo -e "\n\033[1;34m--- Instalando STUNNEL4 (SSL) ---\033[0m"
apt install -y stunnel4
cat > /etc/stunnel/stunnel.conf <<'EOF'
cert = /etc/stunnel/stunnel.pem
[ssh]
accept = 443
connect = 22
EOF
openssl req -new -x509 -days 3650 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com"
chmod 600 /etc/stunnel/stunnel.pem
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
systemctl enable stunnel4 && systemctl restart stunnel4

echo -e "\n\033[1;34m--- Bloqueando torrents en iptables ---\033[0m"
iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP
iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP
iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce" --algo bm -j DROP
iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP
iptables-save > /etc/iptables.up.rules

echo -e "\n\033[1;34m--- Configuración final de firewall y puertos ---\033[0m"
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 110/tcp
ufw allow 222/tcp
ufw allow 3128/tcp
ufw allow 8080/tcp
ufw allow 7300/udp
ufw --force enable

echo -e "\n\033[1;32m==== Instalación COMPLETA ====\033[0m"
echo "Servicios:"
echo " - SSH: 22, 443"
echo " - Dropbear: 110, 443, 222"
echo " - Squid: 3128, 8080"
echo " - WebSocket SSH (relax): 80"
echo " - BADVPN UDPGW: 7300"
echo " - SSL: 443"
echo ""
echo "Verifica dominio, Cloudflare Naranja activo y puertos abiertos."
echo "Prueba tu WebSocket: websocat ws://tudominio:80"
echo ""
echo "Puedes dejar el ws-relax.js siempre activo con PM2 o SCREEN:"
echo "  npm install -g pm2 && pm2 start ws-relax.js --name websocket-ssh"
echo ""
