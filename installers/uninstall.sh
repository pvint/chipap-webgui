#!/bin/bash
chipap_dir="/etc/chipap"
chipap_user="www-data"
version=`sed 's/\..*//' /etc/debian_version`

# Determine version and set default home location for lighttpd 
if [ $version -ge 8 ]; then
    version_msg="Raspian version 8.0 or later"
    webroot_dir="/var/www/html"
else
    version_msg="Raspian version earlier than 8.0"
    webroot_dir="/var/www"
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

# Checks to make sure uninstallation info is correct
function config_uninstallation() {
    install_log "Configure installation"
    echo "Detected ${version_msg}" 
    echo "Install directory: ${chipap_dir}"
    echo "Lighttpd directory: ${webroot_dir}"
    echo -n "Uninstall ChipAP with these values? [y/N]: "
    read answer
    if [[ $answer != "y" ]]; then
        echo "Installation aborted."
        exit 0
    fi
}

# Checks for/restore backup files
function check_for_backups() {
    if [ -d "$chipap_dir/backups" ]; then
        if [ -f "$chipap_dir/backups/interfaces" ]; then
            echo -n "Restore the last interfaces file? [y/N]: "
            read answer
            if [[ $answer -eq 'y' ]]; then
                sudo cp "$chipap_dir/backups/interfaces" /etc/network/interfaces
            fi
        fi
        if [ -f "$chipap_dir/backups/hostapd.conf" ]; then
            echo -n "Restore the last hostapd configuration file? [y/N]: "
            read answer
            if [[ $answer -eq 'y' ]]; then
                sudo cp "$chipap_dir/backups/hostapd.conf" /etc/hostapd/hostapd.conf
            fi
        fi
        if [ -f "$chipap_dir/backups/dnsmasq.conf" ]; then
            echo -n "Restore the last dnsmasq configuration file? [y/N]: "
            read answer
            if [[ $answer -eq 'y' ]]; then
                sudo cp "$chipap_dir/backups/dnsmasq.conf" /etc/dnsmasq.conf
            fi
        fi
        if [ -f "$chipap_dir/backups/dhcpcd.conf" ]; then
            echo -n "Restore the last dhcpcd.conf file? [y/N]: "
            read answer
            if [[ $answer -eq 'y' ]]; then
                sudo cp "$chipap_dir/backups/dhcpcd.conf" /etc/dhcpcd.conf
            fi
        fi
        if [ -f "$chipap_dir/backups/rc.local" ]; then
            echo -n "Restore the last rc.local file? [y/N]: "
            read answer
            if [[ $answer -eq 'y' ]]; then
                sudo cp "$chipap_dir/backups/rc.local" /etc/rc.local
            else
                echo -n "Remove ChipAP Lines from /etc/rc.local? [Y/n]: "
                if $answer -ne 'n' ]]; then
                    sed -i '/#RASPAP/d' /etc/rc.local
                fi
            fi
        fi
    fi
}

# Removes ChipAP directories
function remove_chipap_directories() {
    install_log "Removing ChipAP Directories"
    if [ ! -d "$chipap_dir" ]; then
        install_error "ChipAP Configuration directory not found. Exiting!"
    fi

    if [ ! -d "$webroot_dir" ]; then
        install_error "ChipAP Installation directory not found. Exiting!"
    fi

    sudo rm -rf "$webroot_dir"/*
    sudo rm -rf "$chipap_dir"

}

# Removes www-data from sudoers
function clean_sudoers() {
    # should this check for only our commands?
    sudo sed -i '/www-data/d' /etc/sudoers
}

function remove_chipap() {
    config_uninstallation
    check_for_backups
    remove_chipap_directories
    clean_sudoers
}

remove_chipap
