#!/bin/env sh
# Unix Enumeration Compact

color() {
  local input,color_code
  if [ -t 0 ]; then
      input="$1"
      shift
  else
      input=$(cat)
  fi
  if echo "$1" | grep -qE '^[0-9]+$'; then
      color_code="$1"
  else
      case "$1" in
          black) color_code=0 ;;
          red) color_code=1 ;;
          green) color_code=2 ;;
          yellow) color_code=3 ;;
          blue) color_code=4 ;;
          magenta) color_code=5 ;;
          cyan) color_code=6 ;;
          white) color_code=7 ;;
          *) color_code=7 ;;
      esac
  fi
  printf "\033[38;5;%dm%s\033[0m\n" "$color_code" "$input"
}

header() {
  local h="$1"
  local term_width=$(tput cols)
  local h_len=${#h}
  local dash_count=$(( (term_width - h_len) / 2 ))
  local line=$(printf "%-${dash_count}s" "" | sed 's/ /─/g')
  local right_padding=$((term_width - 2 * dash_count - h_len - 2))
  local right_line=$(printf "%-${right_padding}s" "" | sed 's/ /─/g')
  local header_line="${line} ${h} ${line}${right_line}"
  if [ $(( (term_width - h_len) % 3 )) -eq 0 ]; then
      printf "\033[33m%s\033[0m \033[32m%s\033[0m \033[33m%s\033[0m\n" "$line" "$h" "$line"
  else
      printf "\033[33m%s\033[0m \033[32m%s\033[0m \033[33m%s─\033[0m\n" "$line" "$h" "$line"
  fi
}

run() {
  if [ "$#" -lt 2 ]; then
      printf 'Usage: run "description" "command" ["command2"...]\n' >&2
      return 1
  fi
  description="$1"
  shift
  header_shown=0
  for cmd in "$@"; do
      first_cmd=$(printf '%s\n' "$cmd" | awk -F'[| ]' '{print $1}')
      if ! command -v "$first_cmd" >/dev/null 2>&1; then
          continue
      fi
      if output=$(sh -c "$cmd" 2>/dev/null); then
          if [ $? -eq 0 ] && [ -n "$output" ]; then
              if [ $header_shown -eq 0 ]; then
                  header "$description"
                  header_shown=1
              fi
              printf '%s\n' "$output"
              return 0
          fi
      fi
  done
  return 1
}

runc() {
  if [ "$#" -lt 2 ]; then
      printf 'Usage: run "description" "command" ["command2"...]\n' >&2
      return 1
  fi
  description="$1"
  shift
  header_shown=0
  for cmd in "$@"; do
      first_cmd=$(printf '%s\n' "$cmd" | awk -F'[| ]' '{print $1}')
      if ! command -v "$first_cmd" >/dev/null 2>&1; then
          continue
      fi
      if output=$(sh -c "$cmd" 2>&1); then
          if [ $? -eq 0 ] && [ -n "$output" ]; then
              if [ $header_shown -eq 0 ]; then
                  header "$description"
                  header_shown=1
              fi
              printf '%s\n' "$output" | column
              return 0
          fi
      fi
  done
  return 1
}

info() {
  header "System Informations"
  echo "\033[32mOS\033[0m = $(uname -n 2>/dev/null) $(uname -s 2>/dev/null) $(uname -m 2>/dev/null) [$(uname -o 2>/dev/null)]"
  echo "\033[32m├\033[0m \033[32mKernel\033[0m = $(uname -r 2>/dev/null)"
  echo "\033[32m├\033[0m \033[32mVersion\033[0m = $(uname -v  2>/dev/null)"
  echo "\033[32m├\033[0m \033[32mKernelInfo\033[0m = $(cat /proc/version 2>/dev/null)"
  echo "\033[32m├\033[0m \033[32mUptime\033[0m = $(uptime --pretty | sed -e 's/up //g' -e 's/ days/d/g' -e 's/ day/d/g' -e 's/ hours/h/g' -e 's/ hour/h/g' -e 's/ minutes/m/g' -e 's/, / /g' 2>/dev/null)"
  echo "\033[32m├\033[0m \033[32mShell\033[0m = $($SHELL --version 2>/dev/null)"
  echo "\033[32m├\033[0m \033[32mCPU\033[0m = $(lscpu | grep 'Model name:' | sed 's/Model name:[ \t]*//' 2>/dev/null)"
  mem_used=$(free -m | awk '/Mem:/ {print $3}')
  mem_total=$(free -m | awk '/Mem:/ {print $2}')
  mem_percent=$((100 * mem_used / mem_total))
  mem_bar=$(printf "[%-20s]" "$(printf '=%.0s' $(seq 1 $((mem_percent / 5))))" )
  echo "\033[32m├\033[0m \033[32mMemory\033[0m = $mem_bar $mem_used MiB / $mem_total MiB ($mem_percent%)"
  disk_used=$(df -h / | awk 'NR==2 {print $3}')
  disk_total=$(df -h / | awk 'NR==2 {print $2}')
  disk_percent=$(df -h / | awk 'NR==2 {print $5}')
  disk_bar=$(printf "[%-20s]" "$(printf '=%.0s' $(seq 1 $(( ${disk_percent%\%} / 5 ))))")
  echo "\033[32m├\033[0m \033[32mDisk\033[0m = $disk_bar $disk_used / $disk_total ($disk_percent)"
  echo "\033[32m├\033[0m \033[32mUser\033[0m = $(id 2>/dev/null)"
  echo "\033[32m└\033[0m \033[32mLocal Ip\033[0m = $(ip route get 1 | awk '{print $7; exit}' 2>/dev/null)"
  local pathinfo="$PATH"
  if [ -n "$pathinfo" ]; then
    header "Path Information"
    echo "$PATH" | tr ':' '\n' | column
    OLDIFS="$IFS"
    IFS=':'
    has_writable=0
    writable_dirs=""
    for dir in $pathinfo; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            has_writable=1
            if [ -z "$writable_dirs" ]; then
                writable_dirs="$dir"
            else
                writable_dirs="$writable_dirs $dir"
            fi
        fi
    done
    header "Writable Paths"
    IFS="$OLDIFS"
    if [ "$has_writable" -eq 1 ]; then
        printf '%s\n' "$writable_dirs" | tr ' ' '\n' | column
    fi
  fi
  run "Last Logged Users" "w"
  run "Hashes in /etc/passwd" "grep -v '^[^:]*:[x]' /etc/passwd"
  runc "Group Memberships" "cut -d':' -f1 /etc/passwd | xargs -n1 id"
  runc "Contents of /etc/passwd" "cat /etc/passwd"
  runc "Shadow File Readability Check" "cat /etc/shadow"
  run "Environment Information" "env | grep -v 'LS_COLORS'"
  run "SELinux Status" "sestatus"
  runc "Available Shells" "cat /etc/shells"
  header "Umask Settings"
  echo "Current umask value: $(umask -S 2>/dev/null) ($(umask 2>/dev/null))"
  umask_def=$(grep -i "^UMASK" /etc/login.defs 2>/dev/null)
  if [ -n "$umask_def" ]; then
      echo "Umask value as specified in /etc/login.defs: $umask_def"
  fi
  run "Login Definitions" "grep -E '^(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|ENCRYPT_METHOD)' /etc/login.defs"
  header "Useful Binaries"
  usefulbins="aria2c arp ash awk base64 bash busybox cat chmod chown cp csh curl cut dash date dd diff dmsetup docker ed emacs env expand expect file find flock fmt fold ftp gawk gdb gimp git grep head ht iftop ionice ip irb jjs jq jrunscript ksh ld.so ldconfig less logsave lua make man mawk more mv mysql nano nawk nc netcat nice nl nmap node od openssl perl pg php pic pico python readelf rlwrap rpm rpmquery rsync ruby run-parts rvim scp script sed setarch sftp sh shuf socat sort sqlite3 ssh start-stop-daemon stdbuf strace systemctl tail tar taskset tclsh tee telnet tftp time timeout ul unexpand uniq unshare vi vim watch wget wish xargs xxd zip zsh"
  results=""
  for binary in $usefulbins; do
      path=$(which "$binary" 2>/dev/null)
      if [ -n "$path" ]; then
          results="${results}${path} "
      fi
  done
  echo "$results" | tr ' ' '\n' | sort -u | column
}

network() {
  run "ARP Table" "arp -a" "ip neighbor"
  run "IP Addresses and Interfaces" "ip -br -c a" "ifconfig -a"
  run "Routes" "ip -br route show | grep -v '^default' | sort -u" "route -n"
  run "IPTables Rules" "iptables -L"
  run "Open Ports (ss)" "ss -tulnp | grep LISTEN" "netstat -anp | grep ESTABLISHED"
  run "Nameserver(s) (/etc/resolv.conf)" "echo $nsinfo"
  run "Nameserver(s)" "systemd-resolve --status"
  run "Default Route" "route -n | grep '^0.0.0.0'" "ip route | grep default"
  run "Listening TCP Services" "netstat -ntpl" "ss -t -l -n"
  run "Listening UDP Services" "netstat -nupl" "ss -u -l -n"
  run "Process Tree" "ps auxww | grep -vE '(\[|systemd|kworker|kthreadd|migration|dbus|polkit|avahi|udevd|wpa_supplicant|bluetooth|NetworkManager|logind|Xorg|gdm|gnome|xfce|gvfs|udisks2|upowerd|firefox|chrome|bash|zsh|sshd|kdeinit|cron|cupsd|tty|init)'"
}

scan() {
  run "Sensitive File Permissions" "ls -la /etc/passwd" "ls -la /etc/group" "ls -la /etc/profile" "ls -la /etc/shadow" "ls -la /etc/master.passwd"
  run "SUID Files" "find / -perm -4000 -type f -exec ls -la {} \;"
  run "Interesting SUID Files" "find / -perm -4000 -type f | grep -w $binarylist"
  run "World-Writable SUID Files" "find / -perm -4002 -type f -exec ls -la {} \;"
  run "World-Writable SUID Files Owned by Root" "find / -uid 0 -perm -4002 -type f -exec ls -la {} \;"
  run "SGID Files" "find / -perm -2000 -type f -exec ls -la {} \;"
  run "Interesting SGID Files" "find / -perm -2000 -type f | grep -w $binarylist"
  run "World-Writable SGID Files" "find / -perm -2002 -type f -exec ls -la {} \;"
  run "World-Writable SGID Files Owned by Root" "find / -uid 0 -perm -2002 -type f -exec ls -la {} \;"
  run "Files with POSIX Capabilities" "getcap -r / 2>/dev/null || /sbin/getcap -r / 2>/dev/null"
  run "Users with Specific POSIX Capabilities" "grep -v '^#\|none\|^$' /etc/security/capability.conf"
  run "Private SSH Keys" "grep -rl 'PRIVATE KEY-----' /home"
  run "AWS Secret Keys" "grep -rli 'aws_secret_access_key' /home"
  run "Git Credentials" "find / -name '.git-credentials'"
  run "World-Writable Files" "find / ! -path '*/proc/*' ! -path '/sys/*' -perm -2 -type f -exec ls -la {} \;"
  run "Accessible Plan Files" "find /home -iname '*.plan' -exec cat {} \;"
  run "Accessible .rhosts Files" "find /home -iname '*.rhosts' -exec cat {} \;"
  run "Hosts Equiv Details" "cat /etc/hosts.equiv"
  run "NFS Config Details" "cat /etc/exports"
  run "Contents of WWW Directories" "ls -alhR /var/www/ /srv/www/htdocs/ /usr/local/www/apache2/data/ /opt/lampp/htdocs/"
  run "SSH Configuration Files Listing" "find / -type f \( -name 'id_*sa*' -o -name 'known_hosts' -o -name 'authorized_keys' \) -exec ls -l {} \;"
  run "Sudo version" "sudo -V | grep 'Sudo version'"
  run "MYSQL version" "mysql --version"
  run "MYSQL Default Root Connection" "mysqladmin -uroot -proot version"
  run "MYSQL Root Connection No Password" "mysqladmin -uroot version"
  run "Postgres version" "psql -V"
  run "Postgres DB 'template0' Default Connection as 'postgres'" "psql -U postgres -w template0 -c 'select version()' | grep version"
  run "Postgres DB 'template1' Default Connection as 'postgres'" "psql -U postgres -w template1 -c 'select version()' | grep version"
  run "Apache version" "apache2 -v; httpd -v"
  run "Apache user configuration" "grep -i 'user\|group' /etc/apache2/envvars | awk '{sub(/.*export /,"")}1'"
  run "Installed Apache modules" "apache2ctl -M; httpd -M"
  run "htpasswd check" "find / -name .htpasswd -exec cat {} \; 2>/dev/null"
  run "www home dir contents" "ls -alhR /var/www/; ls -alhR /srv/www/htdocs/; ls -alhR /usr/local/www/apache2/data/; ls -alhR /opt/lampp/htdocs/"
  run "INETD Configuration" "cat /etc/inetd.conf" "awk '{print \$7}' /etc/inetd.conf | xargs -I {} ls -la {} 2>/dev/null"
  run "XINETD Configuration" "cat /etc/xinetd.conf" "grep '/etc/xinetd.d' /etc/xinetd.conf" "awk '{print \$7}' /etc/xinetd.conf | xargs -I {} ls -la {} 2>/dev/null"
  run "Init Scripts and Permissions" "ls -la /etc/init.d" "find /etc/init.d/ ! -uid 0 -type f | xargs -I {} ls -la {} 2>/dev/null"
  run "RC.D Scripts and Permissions" "ls -la /etc/rc.d/init.d" "find /etc/rc.d/init.d ! -uid 0 -type f | xargs -I {} ls -la {} 2>/dev/null"
  run "Cron Jobs Configuration" "ls -la /etc/cron*" "cat /etc/crontab" "ls -la /var/spool/cron/crontabs"
  run "World-Writable Cron Jobs and File Contents" "find /etc/cron* -perm -0002 -type f -exec ls -la {} \; -exec cat {} \;"
  run "Crontab Contents" "cat /etc/crontab"
  run "/var/spool/cron/crontabs Contents" "ls -la /var/spool/cron/crontabs"
  run "Anacron Jobs and Permissions" "ls -la /etc/anacrontab; cat /etc/anacrontab" "ls -la /var/spool/anacron"
  run "/var/spool/anacron Contents" "ls -la /var/spool/anacron"
  if [ -f /etc/crontab ]; then
      header "Cron Jobs and Scheduled Tasks"
      crontab -l 2>/dev/null
      cat /etc/crontab 2>/dev/null
      while IFS=: read -r user _; do
          echo "\nCron jobs for user $user:"
          crontab -u "$user" -l 2>/dev/null
      done < /etc/passwd
  fi
  run "Docker Checks" "grep -i docker /proc/self/cgroup || find / -name '*dockerenv*' -exec ls -la {} \;" "docker --version && docker ps -a" "id | grep -i docker" "find / -name 'Dockerfile' -exec ls -l {} \;" "find / -name 'docker-compose.yml' -exec ls -l {} \;"
  run "LXC/LXD Container Checks" "grep -qa container=lxc /proc/1/environ && echo 'LXC container environment detected'" "id | grep -i lxd"
  run "VMware Checks" "systemctl status vmtoolsd.service" "lsmod | grep -i vmw"
}

usage() {
  echo "Usage: $0 [options]\nOptions:\n  -h   Show help message\n  -i   Run info\n  -n   Run network\n  -s   Run scan"
}

tput rmam
while getopts ":hins" option; do
    case "$option" in
        h)  usage ;;
        i)  info ;;
        n)  network ;;
        s)  scan ;;
        \?) echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :)  echo "Option -$OPTARG requires an argument." >&2
            exit 1 ;;
    esac
done
shift $((OPTIND-1))
tput smam
