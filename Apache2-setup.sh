#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo${NC}"
    exit 1
fi

# Function to display header
header() {
    clear
    echo -e "${GREEN}"
    echo "##################################################"
    echo "#          Apache2 Configuration Script          #"
    echo "##################################################"
    echo -e "${NC}"
}

# Function to check previous command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Success${NC}"
        return 0
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Update package lists
update_packages() {
    header
    echo -e "${YELLOW}Updating package lists...${NC}"
    apt-get update
    check_status
    sleep 1
}

# Install Apache2
install_apache() {
    header
    if systemctl is-active --quiet apache2; then
        echo -e "${YELLOW}Apache2 is already installed and running${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Installing Apache2...${NC}"
    apt-get install -y apache2
    check_status
    sleep 1
}

# Configure firewall
configure_firewall() {
    header
    echo -e "${YELLOW}Configuring firewall...${NC}"
    if command -v ufw &> /dev/null; then
        ufw allow "Apache Full"
        ufw reload
        check_status
    else
        echo -e "${YELLOW}ufw not installed, skipping firewall configuration${NC}"
    fi
    sleep 1
}

# Create virtual host
create_virtual_host() {
    header
    echo -e "${YELLOW}Creating Virtual Host Configuration${NC}"
    
    read -p "Enter domain name (e.g., example.com): " domain
    document_root="/var/www/${domain}/html"
    
    read -p "Enter document root [${document_root}]: " custom_root
    [ -n "$custom_root" ] && document_root=$custom_root
    
    # Create directories
    mkdir -p "${document_root}"
    chown -R www-data:www-data "/var/www/${domain}"
    chmod -R 755 "/var/www/${domain}"
    
    # Create sample index.html
    cat <<- EOF > "${document_root}/index.html"
<html>
    <head>
        <title>Welcome to ${domain}</title>
    </head>
    <body>
        <h1>Success! The ${domain} virtual host is working!</h1>
    </body>
</html>
EOF

    # Create virtual host file
    config_file="/etc/apache2/sites-available/${domain}.conf"
    
    cat <<- EOF > "${config_file}"
<VirtualHost *:80>
    ServerAdmin webmaster@${domain}
    ServerName ${domain}
    ServerAlias www.${domain}
    DocumentRoot ${document_root}
    
    ErrorLog \${APACHE_LOG_DIR}/${domain}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain}_access.log combined
</VirtualHost>
EOF

    # Enable site
    a2ensite "${domain}.conf" > /dev/null
    check_status
    
    # Disable default site
    a2dissite 000-default.conf > /dev/null
    
    sleep 1
}

# Configure SSL
configure_ssl() {
    header
    read -p "Do you want to enable SSL with Let's Encrypt? (y/n): " ssl_choice
    if [[ "${ssl_choice}" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing Certbot...${NC}"
        apt-get install -y certbot python3-certbot-apache
        check_status
        
        echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
        certbot --apache -d ${domain} -d www.${domain}
        check_status
        
        # Enable auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        echo -e "${GREEN}SSL configured successfully!${NC}"
    fi
    sleep 1
}

# Final setup steps
finalize_setup() {
    header
    echo -e "${YELLOW}Finalizing configuration...${NC}"
    
    # Enable required modules
    a2enmod rewrite > /dev/null
    systemctl restart apache2
    check_status
    
    echo -e "${GREEN}\nSetup Complete!${NC}"
    
    # Display summary
    echo -e "\n${YELLOW}Summary:${NC}"
    echo -e "Domain: ${domain}"
    echo -e "Document Root: ${document_root}"
    echo -e "SSL Enabled: $([[ "${ssl_choice}" =~ ^[Yy]$ ]] && echo "Yes" || echo "No")"
    echo -e "\nTest your site: curl -I ${domain}"
}

# Main execution flow
main() {
    update_packages
    install_apache
    configure_firewall
    create_virtual_host
    configure_ssl
    finalize_setup
}

# Start main process
main
