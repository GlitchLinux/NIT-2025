
#!/bin/bash

# Function to ask for root password (using sudo for subsequent commands)
ask_for_password() {
    sudo -v
}

# Function to check Apache status
check_apache_status() {
    systemctl status apache2
}

# Function to update the website
update_website() {
    echo "Backing up current website files..."

    # Ensure backup directories exist
    sudo mkdir -p /etc/apache-undo/html/html
    sudo mkdir -p /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf

    # Backup only files, not directories, excluding FILES directory
    sudo cp /var/www/html/index.html /etc/apache-undo/html/html/index.html
    sudo cp /var/www/html/styles.css /etc/apache-undo/html/html/styles.css
    sudo cp /var/www/html/qemu-quickboot.html /etc/apache-undo/html/html/qemu-quickboot.html
    sudo cp /var/www/html/Qemu-QuickBoot.png /etc/apache-undo/html/html/Qemu-QuickBoot.png
    sudo cp /var/www/html/Qemu-QuickBoot-2.png /etc/apache-undo/html/html/Qemu-QuickBoot-2.png
    
    sudo cp /var/www/glitchlinux.wtf/index.html /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/index.html
    sudo cp /var/www/glitchlinux.wtf/styles.css /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/styles.css
    sudo cp /var/www/glitchlinux.wtf/qemu-quickboot.html /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/qemu-quickboot.html
    sudo cp /var/www/glitchlinux.wtf/Qemu-QuickBoot.png /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/Qemu-QuickBoot.png
    sudo cp /var/www/glitchlinux.wtf/Qemu-QuickBoot-2.png /etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/Qemu-QuickBoot-2.png

    # Define temporary directory for cloning the repository
    TEMP_DIR="/tmp/glitchlinux.wtf"
    sudo rm -rf $TEMP_DIR  # Remove any existing temp directory
    sudo mkdir -p $TEMP_DIR
    cd $TEMP_DIR

    # Clone the GitHub repository
    sudo git clone https://github.com/GlitchLinux/glitchlinux.wtf.git $TEMP_DIR

    # Overwrite existing files with new ones if they exist
    for file in index.html styles.css qemu-quickboot.html Qemu-QuickBoot.png Qemu-QuickBoot-2.png; do
        if [[ -f "$TEMP_DIR/$file" ]]; then
            sudo cp "$TEMP_DIR/$file" /var/www/html/
            sudo cp "$TEMP_DIR/$file" /var/www/glitchlinux.wtf/
        else
            echo "Error: $file not found!"
        fi
    done

    # Clean up the temporary directory
    sudo rm -rf $TEMP_DIR

    # Set correct ownership and permissions for Apache to access the files
    sudo chown -R www-data:www-data /var/www/html
    sudo chown -R www-data:www-data /var/www/glitchlinux.wtf
    sudo chmod -R 755 /var/www/html
    sudo chmod -R 755 /var/www/glitchlinux.wtf

    # Restart Apache to apply the changes
    sudo systemctl restart apache2

    # Confirm update
    echo "Website successfully updated, previous configuration has been saved!"
}

# Function to undo the last update
undo_last_update() {
    echo "Restoring the previous website configuration from backup..."

    # Restore files if they exist, but skip the /FILES/ directory
    for file in index.html styles.css qemu-quickboot.html Qemu-QuickBoot.png Qemu-QuickBoot-2.png; do
        if [[ -f "/etc/apache-undo/html/html/$file" ]]; then
            sudo cp "/etc/apache-undo/html/html/$file" /var/www/html/
            sudo cp "/etc/apache-undo/glitchlinux.wtf/glitchlinux.wtf/$file" /var/www/glitchlinux.wtf/
        else
            echo "Error: No backup for $file"
        fi
    done

    # Set correct ownership and permissions
    sudo chown -R www-data:www-data /var/www/html
    sudo chown -R www-data:www-data /var/www/glitchlinux.wtf
    sudo chmod -R 755 /var/www/html
    sudo chmod -R 755 /var/www/glitchlinux.wtf

    # Restart Apache to apply the changes
    sudo systemctl restart apache2

    # Confirm restoration
    echo "Previous configuration was successfully restored from backup, excluding FILES."
}

# Function to reboot the webserver
reboot_webserver() {
    echo "Rebooting webserver..."
    sudo systemctl restart apache2
    echo "Webserver rebooted successfully."
}

# Function to backup webserver files
backup_webserver() {
    echo "Creating backup of webserver files..."
    BACKUP_PATH="/home/$USER/Desktop/Apache-Full-Backup.zip"
    
    # Exclude the /var/www/glitchlinux.wtf/FILES/ directory from the backup
    sudo zip -r $BACKUP_PATH /etc/apache2 /var/www/html /var/www/glitchlinux.wtf -x "/var/www/glitchlinux.wtf/FILES/*"
    
    echo "Backup created at $BACKUP_PATH."
}

# Main menu
main_menu() {
    echo "Choose an option:"
    echo "[1] UPDATE WEBSITE"
    echo "[2] UNDO LAST UPDATE"
    echo "[3] WEBSERVER STATUS"
    echo "[4] WEBSERVER REBOOT"
    echo "[5] WEBSERVER BACKUP"
    echo "[6] EXIT"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            update_website
            main_menu
            ;;
        2)
            undo_last_update
            main_menu
            ;;
        3)
            check_apache_status
            main_menu
            ;;
        4)
            reboot_webserver
            main_menu
            ;;
        5)
            backup_webserver
            main_menu
            ;;
        6)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            main_menu
            ;;
    esac
}

# Ask for root password at the start
ask_for_password

# Run the main menu
main_menu
