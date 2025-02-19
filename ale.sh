#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}Starting MDM Bypass and Admin User Creation...${NC}"

# Mount Volumes
echo -e "${BLUE}Mounting System and Data volumes...${NC}"
diskutil mount "/Volumes/Macintosh HD"
diskutil mount "/Volumes/Macintosh HD - Data"

# Define paths
SYSTEM_PATH="/Volumes/Macintosh HD"
DATA_PATH="/Volumes/Macintosh HD - Data"
DSCL_PATH="$DATA_PATH/private/var/db/dslocal/nodes/Default"

# Create admin user
echo -e "${BLUE}Creating admin user...${NC}"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" UserShell "/bin/zsh"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" RealName "Admin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" UniqueID "501"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" PrimaryGroupID "20"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" NFSHomeDirectory "/Users/admin"
dscl -f "$DSCL_PATH" localhost -passwd "/Local/Default/Users/admin" "admin123"
dscl -f "$DSCL_PATH" localhost -append "/Local/Default/Groups/admin" GroupMembership "admin"

# Create admin user directory
mkdir -p "$DATA_PATH/Users/admin"

# Skip Setup Assistant
touch "$DATA_PATH/private/var/db/.AppleSetupDone"

# Block MDM domains
echo -e "${BLUE}Blocking MDM domains...${NC}"
cat >> "$SYSTEM_PATH/etc/hosts" << EOF
0.0.0.0 deviceenrollment.apple.com
0.0.0.0 mdmenrollment.apple.com
0.0.0.0 iprofiles.apple.com
0.0.0.0 Albert.apple.com
0.0.0.0 axm-adm-enroll.apple.com
0.0.0.0 comm.support.apple.com
0.0.0.0 push.apple.com
0.0.0.0 identity.apple.com
EOF

# Remove MDM profiles
echo -e "${BLUE}Removing MDM profiles...${NC}"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles"
rm -rf "$DATA_PATH/private/var/db/ConfigurationProfiles"
rm -rf "$SYSTEM_PATH/Library/ConfigurationProfiles"

# Clear activation record
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
touch "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
touch "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"

# Disable MDM services
launchctl unload "/Library/LaunchDaemons/com.apple.mdmclient.daemon.plist" 2>/dev/null
launchctl unload "/Library/LaunchAgents/com.apple.mdmclient.agent.plist" 2>/dev/null

echo -e "${GREEN}Process completed!${NC}"
echo -e "${BLUE}Admin user created with:${NC}"
echo -e "Username: admin"
echo -e "Password: admin123"
echo -e "\n${GREEN}Please restart your Mac now.${NC}"
