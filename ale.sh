#!/bin/bash

# Global constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Verify we're running in recovery mode
check_recovery_mode() {
    if [ ! -d "/Volumes/Macintosh HD" ] && [ ! -d "/Volumes/Data" ]; then
        echo -e "${YELLOW}Warning: Make sure you're running this in Recovery Mode${NC}"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Enhanced MDM domain blocking
block_mdm_domains() {
    local hostsPath="$1"
    local domains=(
        "deviceenrollment.apple.com"
        "mdmenrollment.apple.com"
        "iprofiles.apple.com"
        "albert.apple.com"
        "gateway.push.apple.com"
        "metrics.apple.com"
        "profile.ess.apple.com"
        "profiles.apple.com"
        "setup.icloud.com"
        "sq-device.apple.com"
        "serverstatus.apple.com"
        "axm-adm-enroll.apple.com"
        "over-the-air.ess.apple.com"
        "push.apple.com"
        "comm.support.apple.com"
    )
    
    echo -e "${BLUE}Blocking MDM domains...${NC}"
    for domain in "${domains[@]}"; do
        echo "0.0.0.0 $domain" >> "$hostsPath" || handle_error "Failed to block $domain"
    done
    echo -e "${GREEN}Successfully blocked all MDM domains${NC}"
}

# Enhanced MDM profile removal
remove_mdm_profiles() {
    local systemVolumePath="$1"
    local dataVolumePath="$2"
    
    echo -e "${BLUE}Removing MDM profiles and related files...${NC}"
    
    # Configuration Profiles
    local configProfilesPath="$systemVolumePath/var/db/ConfigurationProfiles"
    rm -rf "$configProfilesPath/Settings/.cloudConfigHasActivationRecord"
    rm -rf "$configProfilesPath/Settings/.cloudConfigRecordFound"
    rm -rf "$configProfilesPath/Store"
    touch "$configProfilesPath/Settings/.cloudConfigProfileInstalled"
    touch "$configProfilesPath/Settings/.cloudConfigRecordNotFound"
    
    # MDM Client
    rm -rf "$systemVolumePath/Library/LaunchDaemons/com.apple.mdmclient.daemon.plist"
    rm -rf "$systemVolumePath/Library/LaunchAgents/com.apple.mdmclient.agent.plist"
    
    # JAMF and other MDM solutions
    rm -rf "$systemVolumePath/Library/Application Support/JAMF"
    rm -rf "$systemVolumePath/Library/LaunchDaemons/com.jamf"
    rm -rf "$systemVolumePath/usr/local/jamf"
    rm -rf "$systemVolumePath/var/db/ConfigurationProfiles"
    
    # Additional MDM-related files
    rm -rf "$dataVolumePath/private/var/db/ConfigurationProfiles"
    touch "$dataVolumePath/private/var/db/.AppleSetupDone"
    
    echo -e "${GREEN}MDM profiles and related files removed${NC}"
}

# Disable MDM services
disable_mdm_services() {
    local systemVolumePath="$1"
    echo -e "${BLUE}Disabling MDM services...${NC}"
    
    # Create script to disable services on next boot
    cat > "$systemVolumePath/Library/LaunchDaemons/disable.mdm.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>disable.mdm</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>launchctl unload /Library/LaunchDaemons/com.apple.mdmclient.daemon.plist; launchctl unload /Library/LaunchAgents/com.apple.mdmclient.agent.plist</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    
    chmod 644 "$systemVolumePath/Library/LaunchDaemons/disable.mdm.plist"
    echo -e "${GREEN}MDM services disabled${NC}"
}

# Verify bypass success
verify_bypass() {
    echo -e "${BLUE}Verifying MDM bypass...${NC}"
    local success=true
    
    # Check for common MDM files
    for file in "/Library/LaunchDaemons/com.apple.mdmclient.daemon.plist" \
                "/Library/LaunchAgents/com.apple.mdmclient.agent.plist" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"; do
        if [ -f "$file" ]; then
            echo -e "${RED}Warning: MDM file still exists: $file${NC}"
            success=false
        fi
    done
    
    if [ "$success" = true ]; then
        echo -e "${GREEN}Verification complete: MDM appears to be successfully bypassed${NC}"
    else
        echo -e "${YELLOW}Verification complete: Some MDM files still exist${NC}"
    fi
}

# Main bypass function
perform_bypass() {
    echo -e "\n${GREEN}Starting Enhanced MDM Bypass...${NC}\n"
    
    # Check if we're in recovery mode
    check_recovery_mode
    
    # Mount volumes
    echo -e "${BLUE}Mounting volumes...${NC}"
    systemVolumePath=$(defineVolumePath "$DEFAULT_SYSTEM_VOLUME" "System")
    mountVolume "$systemVolumePath"
    dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
    mountVolume "$dataVolumePath"
    echo -e "${GREEN}Volumes mounted successfully${NC}\n"
    
    # Perform bypass steps
    block_mdm_domains "$systemVolumePath/etc/hosts"
    remove_mdm_profiles "$systemVolumePath" "$dataVolumePath"
    disable_mdm_services "$systemVolumePath"
    verify_bypass
    
    echo -e "\n${GREEN}MDM Bypass process completed${NC}"
    echo -e "${CYAN}Please restart your computer now${NC}"
    echo -e "${YELLOW}Note: After restart, if you see any MDM prompts, decline them and check System Preferences > Profiles${NC}"
}

# Main menu
PS3='Please enter your choice: '
options=("Run Enhanced MDM Bypass" "Verify MDM Status" "Reboot" "Exit")

select opt in "${options[@]}"; do
    case $opt in
        "Run Enhanced MDM Bypass")
            perform_bypass
            break
            ;;
        "Verify MDM Status")
            if [ ! -f /usr/bin/profiles ]; then
                echo -e "\n${RED}Cannot verify MDM status in recovery mode${NC}\n"
            else
                verify_bypass
            fi
            ;;
        "Reboot")
            echo -e "\n${BLUE}Rebooting...${NC}\n"
            reboot
            ;;
        "Exit")
            echo -e "\n${BLUE}Exiting...${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option $REPLY${NC}"
            ;;
    esac
done
