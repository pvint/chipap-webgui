UPDATE_URL="https://raw.githubusercontent.com/billz/chipap-webgui/master/"
wget -q ${UPDATE_URL}/installers/common.sh -O /tmp/chipapcommon.sh
source /tmp/chipapcommon.sh && rm -f /tmp/chipapcommon.sh

function update_system_packages() {
    install_log "Updating sources"
    sudo apt-get update || install_error "Unable to update package list"
}

function install_dependencies() {
    install_log "Installing required packages"
    sudo apt-get install lighttpd $php_package git hostapd dnsmasq || install_error "Unable to install dependencies"
}

install_chipap
