#!/bin/bash

# Update and upgrade system
apt update && apt upgrade -y

# Install required package
apt install -y dos2unix curl git

# Install Webmin
curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh
echo "y" | sh webmin-setup-repos.sh
apt install -y webmin --install-recommends

# Clone the repository and move script to home directory
git clone https://github.com/sprocket78/R-Stes-Nginx-Proxy-Installer-v1.0.git /tmp/nginx-proxy-installer
cp /tmp/nginx-proxy-installer/nginx.sh /home/

# Convert nginx.sh to Unix format and make it executable
dos2unix /home/nginx.sh
chmod +x /home/nginx.sh

# Execute nginx.sh
/home/nginx.sh

# Cleanup
echo "Installation complete!"
