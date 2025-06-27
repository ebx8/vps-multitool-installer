const net = require('net');
const http = require('http');
const server = http.createServer();
server.on('upgrade', (req, socket) => {
    // Modo relax: acepta cualquier handshake Upgrade: websocket
    const sshSocket = net.connect({ host: '127.0.0.1', port: 22 }, () => {
        socket.write('HTTP/1.1 101 Switching Protocols\r\n' +
                     'Upgrade: websocket\r\n' +
                     'Connection: Upgrade\r\n' +
                     '\r\n');
        sshSocket.pipe(socket);
        socket.pipe(sshSocket);
    });
    sshSocket.on('error', (err) => { socket.end(); });
    socket.on('error', (err) => { sshSocket.end(); });
});
server.listen(80, () => {
    console.log('WebSocket SSH proxy escuchando en el puerto 80 (modo relax)');
});
