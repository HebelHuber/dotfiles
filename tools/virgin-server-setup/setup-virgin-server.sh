#!/bin/sh

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
BOLD=`tput bold`
RESET=`tput sgr0`
# echo "hello ${RED}some red text${RESET} world"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo or as root"
    exit 1
fi

wait_for_key() {
    echo ""
    printf "%s" "Press Enter to continue..."
    read -r dummy
}

# Install default packages
apt update
if [ -f ./default_packages ]; then
    echo "Installing default packages..."
    xargs -a ./default_packages apt install -y
fi

# Cloudflare Tunnel Token
echo "1. ${MAGENTA}Cloudflare Tunnel Token${RESET} - create one at: https://dash.cloudflare.com/ - Go to: Zero Trust > Access > Tunnels > Create Tunnel"
read -p "${YELLOW}Enter Cloudflare Tunnel Token: ${RESET}" CLOUDFLARE_TUNNEL_TOKEN

# Tailscale Auth Key
echo "2. ${MAGENTA}Tailscale Auth Key${RESET} - create one at: https://login.tailscale.com/admin/settings/keys"
read -p "${YELLOW}Enter Tailscale Auth Key: ${RESET}" TAILSCALE_AUTH_KEY

# Hostname
read -p "${YELLOW}3. Enter hostname (for both Tailscale and this machine): ${RESET}" TAILSCALE_AND_MACHINE_HOSTNAME

# Tunnel public hostname
read -p "${YELLOW}4. Enter Cloudflare Tunnel public hostname for Cockpit [${TAILSCALE_AND_MACHINE_HOSTNAME}-cockpit.kiefercloud.com]: ${RESET}" CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN
CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN=${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN:-${TAILSCALE_AND_MACHINE_HOSTNAME}-cockpit.kiefercloud.com}

# Timezone
read -p "${YELLOW}5. Enter timezone [Europe/Berlin]: ${RESET}" TIMEZONE
TIMEZONE=${TIMEZONE:-Europe/Berlin}

# double check vars

echo ""
echo "         CLOUDFLARE_TUNNEL_TOKEN = ${CLOUDFLARE_TUNNEL_TOKEN}"
echo "              TAILSCALE_AUTH_KEY = ${TAILSCALE_AUTH_KEY}"
echo "  TAILSCALE_AND_MACHINE_HOSTNAME = ${TAILSCALE_AND_MACHINE_HOSTNAME}"
echo " CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN = ${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN}"
echo "                        TIMEZONE = ${TIMEZONE}"

wait_for_key

# input section end

# Set timezone
timedatectl set-timezone $TIMEZONE

# Set hostname
hostnamectl set-hostname $TAILSCALE_AND_MACHINE_HOSTNAME

# Setup firewall
ufw --force disable
ufw --force reset
ufw allow proto tcp to 0.0.0.0/0 port 22 comment 'allow SSH from anywhere'
ufw allow in on tailscale0 comment 'allow incoming from tailnet'
ufw allow from 192.168.178.0/24 comment 'allow everything from LAN'
ufw --force enable
ufw status verbose

# Setup ssh server
# cp authorize_ssh.sh /usr/local/bin/authorize_ssh.sh
# chmod +x /usr/local/bin/authorize_ssh.sh
# rm -f /etc/ssh/sshd_config
cp /home/lukas/tools/virgin-server-setup/ssh/sshd_config /etc/ssh/sshd_config
service ssh restart

# Install cockpit with cockpit-navigator and cockpit-filesharing
. /etc/os-release && apt install -y -t ${VERSION_CODENAME}-backports cockpit
wget -qO - https://repo.45drives.com/key/gpg.asc | sudo gpg --dearmor -o /usr/share/keyrings/45drives-archive-keyring.gpg
sudo curl -sSL https://repo.45drives.com/lists/45drives.sources -o /etc/apt/sources.list.d/45drives.sources
sudo apt update && sudo apt install -y cockpit-navigator cockpit-file-sharing

# Setup cockpit proxy access
rm -f /etc/cockpit/cockpit.conf
cat > /etc/cockpit/cockpit.conf << EOL
[webService]
# accept connections from the specified domains
Origins = https://${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN} wss://${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN} http://${TAILSCALE_AND_MACHINE_HOSTNAME}:9090 https://${TAILSCALE_AND_MACHINE_HOSTNAME}:9090
# let it distinguish if the connection is using TLS by the header
ProtocolHeader = X-Forwarded-Proto 
# allow HTTP connections. This turns off redirects to HTTPS.
AllowUnencrypted = true
EOL

service cockpit start
echo "Cockpit service status:"
systemctl status cockpit --no-pager -l

# install docker
apt update
apt install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# groupadd docker
usermod -aG docker $(logname)
# newgrp docker

# Setup dockge with tailscale and cloudflared
mkdir -p /opt/stacks /opt/dockge
cp /home/lukas/tools/virgin-server-setup/dockge/compose.yaml /opt/dockge/compose.yaml

# Create .env file for dockge
cat > /opt/dockge/.env << EOL
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
TAILSCALE_AUTH_KEY=${TAILSCALE_AUTH_KEY}
TAILSCALE_AND_MACHINE_HOSTNAME=${TAILSCALE_AND_MACHINE_HOSTNAME}
CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN=${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN}
EOL

chown -R $(logname) /opt/stacks
chgrp -R $(logname) /opt/dockge

CURRENT_DIR=$PWD
cd /opt/dockge
docker compose up -d
cd $CURRENT_DIR

# Print setup instructions
echo ""
echo "=============================================="
echo "SETUP INSTRUCTIONS FOR CLOUDFLARE TUNNEL:"
echo "1. Go to Cloudflare Zero Trust dashboard"
echo "2. For Cockpit:"
echo "   - Create a public hostname pointing to http://localhost:9090"
echo "   - enable access control before saveing hostname"
echo "3. For Dockge:"
echo "   - Create a public hostname pointing to http://localhost:5001"
echo "   - enable access control before saveing hostname"
echo "4. Make sure the hostnames match what you entered earlier"
echo ""
echo "ACCESS INSTRUCTIONS:"
echo "You can access the services via:"
echo "1. Cockpit:"
echo "   - Tailscale/LAN: http://${TAILSCALE_AND_MACHINE_HOSTNAME}:9090"
echo "   - Cloudflare Tunnel: https://${CF_TUNNEL_PUBLIC_COCKPIT_DOMAIN}"
echo "2. Dockge:"
echo "   - Tailscale/LAN: http://${TAILSCALE_AND_MACHINE_HOSTNAME}:5001"
echo ""
echo "The system will reboot after you press any key..."
wait_for_key
reboot now
