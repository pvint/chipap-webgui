chipap_dir="/etc/chipap"
chipap_user="www-data"
version=`sed 's/\..*//' /etc/debian_version`

# Determine version, set default home location for lighttpd and 
# php package to install 
webroot_dir="/var/www/html" 
if [ $version -eq 9 ]; then 
    version_msg="Raspian 9.0 (Stretch)" 
    php_package="php7.0-cgi" 
elif [ $version -eq 8 ]; then 
    version_msg="Raspian 8.0 (Jessie)" 
    php_package="php5-cgi" 
else 
    version_msg="Raspian earlier than 8.0 (Wheezy)"
    webroot_dir="/var/www" 
    php_package="php5-cgi" 
fi 

# Outputs a ChipAP Install log line
function install_log() {
    echo -e "\033[1;32mChipAP Install: $*\033[m"
}

# Outputs a ChipAP Install Error log line and exits with status code 1
function install_error() {
    echo -e "\033[1;37;41mChipAP Install Error: $*\033[m"
    exit 1
}

# Outputs a welcome message
function display_welcome() {
    raspberry='\033[0;35m'
    green='\033[1;32m'

    echo -e "${raspberry}\n"
    echo -e " 888888ba                              .d888888   888888ba" 
    echo -e " 88     8b                            d8     88   88     8b" 
    echo -e "a88aaaa8P' .d8888b. .d8888b. 88d888b. 88aaaaa88a a88aaaa8P" 
    echo -e " 88    8b. 88    88 Y8ooooo. 88    88 88     88   88" 
    echo -e " 88     88 88.  .88       88 88.  .88 88     88   88" 
    echo -e " dP     dP  88888P8  88888P  88Y888P  88     88   dP" 
    echo -e "                             88"                             
    echo -e "                             dP"                             
    echo -e "${green}"
    echo -e "The Quick Installer will guide you through a few easy steps\n\n"
}

### NOTE: all the below functions are overloadable for system-specific installs
### NOTE: some of the below functions MUST be overloaded due to system-specific installs

function config_installation() {
    install_log "Configure installation"
    echo "Detected ${version_msg}" 
    echo "Install directory: ${chipap_dir}"
    echo "Lighttpd directory: ${webroot_dir}"
    echo -n "Complete installation with these values? [y/N]: "
    read answer
    if [[ $answer != "y" ]]; then
        echo "Installation aborted."
        exit 0
    fi
}

# Runs a system software update to make sure we're using all fresh packages
function update_system_packages() {
    # OVERLOAD THIS
    install_error "No function definition for update_system_packages"
}

# Installs additional dependencies using system package manager
function install_dependencies() {
    # OVERLOAD THIS
    install_error "No function definition for install_dependencies"
}

# Enables PHP for lighttpd and restarts service for settings to take effect
function enable_php_lighttpd() {
    install_log "Enabling PHP for lighttpd"

    sudo lighttpd-enable-mod fastcgi-php    
    sudo service lighttpd force-reload
    sudo /etc/init.d/lighttpd restart || install_error "Unable to restart lighttpd"
}

# Verifies existence and permissions of ChipAP directory
function create_chipap_directories() {
    install_log "Creating ChipAP directories"
    if [ -d "$chipap_dir" ]; then
        sudo mv $chipap_dir "$chipap_dir.`date +%F-%R`" || install_error "Unable to move old '$chipap_dir' out of the way"
    fi
    sudo mkdir -p "$chipap_dir" || install_error "Unable to create directory '$chipap_dir'"

    # Create a directory for existing file backups.
    sudo mkdir -p "$chipap_dir/backups"

    # Create a directory to store networking configs
    sudo mkdir -p "$chipap_dir/networking"
    # Copy existing dhcpcd.conf to use as base config
    cat /etc/dhcpcd.conf | sudo tee -a /etc/chipap/networking/defaults

    sudo chown -R $chipap_user:$chipap_user "$chipap_dir" || install_error "Unable to change file ownership for '$chipap_dir'"


}

# Generate logging enable/disable files for hostapd
function create_logging_scripts() {
    sudo mkdir /etc/chipap/hostapd
    sudo mv /var/www/html/installers/*log.sh /etc/chipap/hostapd
}

# Generate logging enable/disable files for hostapd
function create_logging_scripts() {
    sudo mkdir /etc/chipap/hostapd
    sudo mv /var/www/html/installers/*log.sh /etc/chipap/hostapd
}

# Fetches latest files from github to webroot
function download_latest_files() {
    if [ -d "$webroot_dir" ]; then
        sudo mv $webroot_dir "$webroot_dir.`date +%F-%R`" || install_error "Unable to remove old webroot directory"
    fi

    install_log "Cloning latest files from github"
    git clone https://github.com/billz/chipap-webgui /tmp/chipap-webgui || install_error "Unable to download files from github"
    sudo mv /tmp/chipap-webgui $webroot_dir || install_error "Unable to move chipap-webgui to web root"
}

# Sets files ownership in web root directory
function change_file_ownership() {
    if [ ! -d "$webroot_dir" ]; then
        install_error "Web root directory doesn't exist"
    fi

    install_log "Changing file ownership in web root directory"
    sudo chown -R $chipap_user:$chipap_user "$webroot_dir" || install_error "Unable to change file ownership for '$webroot_dir'"
}

# Check for existing /etc/network/interfaces and /etc/hostapd/hostapd.conf files
function check_for_old_configs() {
    if [ -f /etc/network/interfaces ]; then
        sudo cp /etc/network/interfaces "$chipap_dir/backups/interfaces.`date +%F-%R`"
        sudo ln -sf "$chipap_dir/backups/interfaces.`date +%F-%R`" "$chipap_dir/backups/interfaces"
    fi

    if [ -f /etc/hostapd/hostapd.conf ]; then
        sudo cp /etc/hostapd/hostapd.conf "$chipap_dir/backups/hostapd.conf.`date +%F-%R`"
        sudo ln -sf "$chipap_dir/backups/hostapd.conf.`date +%F-%R`" "$chipap_dir/backups/hostapd.conf"
    fi

    if [ -f /etc/dnsmasq.conf ]; then
        sudo cp /etc/dnsmasq.conf "$chipap_dir/backups/dnsmasq.conf.`date +%F-%R`"
        sudo ln -sf "$chipap_dir/backups/dnsmasq.conf.`date +%F-%R`" "$chipap_dir/backups/dnsmasq.conf"
    fi

    if [ -f /etc/dhcpcd.conf ]; then
        sudo cp /etc/dhcpcd.conf "$chipap_dir/backups/dhcpcd.conf.`date +%F-%R`"
        sudo ln -sf "$chipap_dir/backups/dhcpcd.conf.`date +%F-%R`" "$chipap_dir/backups/dhcpcd.conf"
    fi

    if [ -f /etc/rc.local ]; then
        sudo cp /etc/rc.local "$chipap_dir/backups/rc.local.`date +%F-%R`"
        sudo ln -sf "$chipap_dir/backups/rc.local.`date +%F-%R`" "$chipap_dir/backups/rc.local"
    fi
}

# Move configuration file to the correct location
function move_config_file() {
    if [ ! -d "$chipap_dir" ]; then
        install_error "'$chipap_dir' directory doesn't exist"
    fi

    install_log "Moving configuration file to '$chipap_dir'"
    sudo mv "$webroot_dir"/chipap.php "$chipap_dir" || install_error "Unable to move files to '$chipap_dir'"
    sudo chown -R $chipap_user:$chipap_user "$chipap_dir" || install_error "Unable to change file ownership for '$chipap_dir'"
}

# Set up default configuration
function default_configuration() {
    install_log "Setting up hostapd"
    if [ -f /etc/default/hostapd ]; then
        sudo mv /etc/default/hostapd /tmp/default_hostapd.old || install_error "Unable to remove old /etc/default/hostapd file"
    fi
    sudo mv $webroot_dir/config/default_hostapd /etc/default/hostapd || install_error "Unable to move hostapd defaults file"
    sudo mv $webroot_dir/config/hostapd.conf /etc/hostapd/hostapd.conf || install_error "Unable to move hostapd configuration file"
    sudo mv $webroot_dir/config/dnsmasq.conf /etc/dnsmasq.conf || install_error "Unable to move dnsmasq configuration file"
    sudo mv $webroot_dir/config/dhcpcd.conf /etc/dhcpcd.conf || install_error "Unable to move dhcpcd configuration file"

    # Generate required lines for Rasp AP to place into rc.local file.
    # #RASPAP is for removal script
    lines=(
    'echo 1 > /proc/sys/net/ipv4/ip_forward #RASPAP'
    'iptables -t nat -A POSTROUTING -j MASQUERADE #RASPAP'
    )
    
    for line in "${lines[@]}"; do
        if grep "$line" /etc/rc.local > /dev/null; then
            echo "$line: Line already added"
        else
            sed -i "s/exit 0/$line\nexit0/" /etc/rc.local
            echo "Adding line $line"
        fi
    done
}


# Add a single entry to the sudoers file
function sudo_add() {
    sudo bash -c "echo \"www-data ALL=(ALL) NOPASSWD:$1\" | (EDITOR=\"tee -a\" visudo)" \
        || install_error "Unable to patch /etc/sudoers"
}

# Adds www-data user to the sudoers file with restrictions on what the user can execute
function patch_system_files() {
    # Set commands array
    cmds=(
        '/sbin/ifdown wlan0'
        '/sbin/ifup wlan0'
        '/bin/cat /etc/wpa_supplicant/wpa_supplicant.conf'
        '/bin/cp /tmp/wifidata /etc/wpa_supplicant/wpa_supplicant.conf'
        '/sbin/wpa_cli scan_results'
        '/sbin/wpa_cli scan'
        '/sbin/wpa_cli reconfigure'
        '/bin/cp /tmp/hostapddata /etc/hostapd/hostapd.conf'
        '/etc/init.d/hostapd start'
        '/etc/init.d/hostapd stop'
        '/etc/init.d/dnsmasq start'
        '/etc/init.d/dnsmasq stop'
        '/bin/cp /tmp/dhcpddata /etc/dnsmasq.conf'
        '/sbin/shutdown -h now'
        '/sbin/reboot'
        '/sbin/ip link set wlan0 down'
        '/sbin/ip link set wlan0 up'
        '/sbin/ip -s a f label wlan0'
        '/bin/cp /etc/chipap/networking/dhcpcd.conf /etc/dhcpcd.conf'
        '/etc/chipap/hostapd/enablelog.sh'
        '/etc/chipap/hostapd/disablelog.sh'
    )

    # Check if sudoers needs patchin
    if [ $(sudo grep -c www-data /etc/sudoers) -ne 15 ]; then
        # Sudoers file has incorrect number of commands. Wiping them out.
        install_log "Cleaning sudoers file"
        sudo sed -i '/www-data/d' /etc/sudoers
        install_log "Patching system sudoers file"
        # patch /etc/sudoers file
        for cmd in "${cmds[@]}"; do
            sudo_add $cmd
        done
    else
        install_log "Sudoers file already patched"
    fi
}

function install_complete() {
    install_log "Installation completed!"

    echo -n "The system needs to be rebooted as a final step. Reboot now? [y/N]: "
    read answer
    if [[ $answer != "y" ]]; then
        echo "Installation aborted."
        exit 0
    fi
    sudo shutdown -r now || install_error "Unable to execute shutdown"
}

function install_chipap() {
    display_welcome
    config_installation
    update_system_packages
    install_dependencies
    enable_php_lighttpd
    create_chipap_directories
    create_logging_scripts
    check_for_old_configs
    download_latest_files
    change_file_ownership
    move_config_file
    default_configuration
    patch_system_files
    install_complete
}
