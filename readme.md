# VPS-MULTITOOL-INSTALLER by ebx

**Instala todo lo necesario para túneles SSH, Proxy, WebSocket, SSL y UDP en Ubuntu 20.04.**

## Instalación rápida

```bash
wget https://github.com/ebx8/vps-multitool-installer/install.sh

chmod +x install.sh
sudo ./install.sh


## ¿Cómo dejar el WebSocket SSH corriendo SIEMPRE?

La forma profesional es usando **pm2** (requiere Node.js 14 o superior):

```bash
npm install -g pm2
cd /opt/wsproxy
pm2 start ws-relax.js --name websocket-ssh
pm2 save
pm2 startup

