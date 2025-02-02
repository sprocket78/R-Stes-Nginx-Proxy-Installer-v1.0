#!/bin/bash

# Blue typing effect
function blue_echo() {
    for char in "$1"; do
        echo -n -e "\033[1;34m$char\033[0m"
        sleep 0.02
    done
    echo ""
}

# Clear screen and show logo
clear
blue_echo "========================================="
blue_echo "    R Ste's Nginx Proxy Installer v1.1   "
blue_echo "========================================="

# Install dependencies
blue_echo "Updating system and installing dependencies..."
apt update -y > /dev/null 2>&1
apt install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev git curl jq ufw > /dev/null 2>&1

# Prompt for ACL, username, and password
blue_echo "Enter the allowed IP or subnet (ACL1):"
read -r ACL1
blue_echo "Enter the allowed IP or subnet (ACL2):"
read -r ACL2
blue_echo "Enter the allowed IP or subnet (ACL3):"
read -r ACL3
blue_echo "Enter a username for SOCKS5 proxy authentication:"
read -r PROXY_USER
blue_echo "Enter a password for SOCKS5 proxy authentication:"
read -r -s PROXY_PASS
echo ""

# Install Nginx with RTMP module
blue_echo "Installing Nginx with RTMP module..."
cd /usr/local/src || exit
git clone https://github.com/arut/nginx-rtmp-module.git > /dev/null 2>&1
wget http://nginx.org/download/nginx-1.25.2.tar.gz > /dev/null 2>&1
tar -xzf nginx-1.25.2.tar.gz > /dev/null 2>&1
cd nginx-1.25.2 || exit
./configure --add-module=../nginx-rtmp-module --with-http_ssl_module > /dev/null 2>&1
make > /dev/null 2>&1
make install > /dev/null 2>&1

# Configure Nginx for RTMP
blue_echo "Configuring Nginx for RTMP streaming..."
cat > /usr/local/nginx/conf/nginx.conf <<EOF
worker_processes 1;
events {
    worker_connections 1024;
}
http {
    include mime.types;
    default_type application/octet-stream;

    server {
        listen 8080;
        location / {
            root html;
            index index.html index.htm;
        }
    }
}
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
        }
    }
}
EOF

# Install Dante for SOCKS5
blue_echo "Installing Dante SOCKS5 proxy server..."
apt install -y dante-server > /dev/null 2>&1
cat > /etc/danted.conf <<EOF
logoutput: stderr
internal: eth0 port = 1080
external: eth0
socksmethod: username  # Replace deprecated "method" with "socksmethod"
user.notprivileged: nobody
client pass {
    from: $ACL1 to: 0.0.0.0/0
    log: connect disconnect
}
client pass {
    from: $ACL2 to: 0.0.0.0/0
    log: connect disconnect
}
client pass {
    from: $ACL3 to: 0.0.0.0/0
    log: connect disconnect
}
socks pass {
    from: $ACL1 to: 0.0.0.0/0
}
socks pass {
    from: $ACL2 to: 0.0.0.0/0
}
socks pass {
    from: $ACL3 to: 0.0.0.0/0
}
EOF

# Create proxy user
blue_echo "Creating SOCKS5 proxy user..."
useradd -m -s /usr/sbin/nologin $PROXY_USER > /dev/null 2>&1
echo "$PROXY_USER:$PROXY_PASS" | chpasswd > /dev/null 2>&1

# Start services
blue_echo "Starting Nginx and Dante services..."
/usr/local/nginx/sbin/nginx
systemctl restart danted > /dev/null 2>&1

# Secure server with UFW and allow access automatically
blue_echo "Securing the server with UFW..."
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow from $ACL1 to any port 1080 proto tcp > /dev/null 2>&1
ufw allow from $ACL2 to any port 1080 proto tcp > /dev/null 2>&1
ufw allow from $ACL3 to any port 1080 proto tcp > /dev/null 2>&1
ufw allow from $ACL1 to any port 1935 proto tcp > /dev/null 2>&1
ufw allow from $ACL2 to any port 1935 proto tcp > /dev/null 2>&1
ufw allow from $ACL3 to any port 1935 proto tcp > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
ufw allow 10000/tcp > /dev/null 2>&1  # Webmin
ufw --force enable > /dev/null 2>&1  # The --force flag will bypass the confirmation prompt

# Gather server details
blue_echo "Gathering server details..."
SERVER_IP=$(curl -s ifconfig.me)
OS_VERSION=$(lsb_release -d | awk -F"\t" '{print $2}')
LOCATION=$(curl -s "https://ipinfo.io/$SERVER_IP?token=demo" | jq -r '.city + ", " + .region + ", " + .country')

# Display access details
blue_echo "Installation and configuration complete!"
blue_echo "========================================="
blue_echo "    R Ste's Nginx Proxy Installer v1.1   "
blue_echo "========================================="
blue_echo "RTMP Streaming Server:"
blue_echo "  - Address: rtmp://$SERVER_IP:1935/live"
blue_echo "SOCKS5 Proxy Server:"
blue_echo "  - Address: $SERVER_IP:1080"
blue_echo "  - Username: $PROXY_USER"
blue_echo "  - Password: (hidden)"
blue_echo "Firewall:"
blue_echo "  - Allowed ACL: $ACL1, $ACL2, $ACL3"
blue_echo "Server Details:"
blue_echo "  - Public IP: $SERVER_IP"
blue_echo "  - OS Version: $OS_VERSION"
blue_echo "  - Location: $LOCATION"
blue_echo "========================================="
