#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NC='\033[0m'

# Create directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

echo -e "${BLUE}Starting MDM Bypass and Admin User Creation...${NC}"

# Mount Volumes
echo -e "${BLUE}Mounting System and Data volumes...${NC}"
diskutil mount "/Volumes/Macintosh HD" || true
diskutil mount "/Volumes/Macintosh HD - Data" || true

# Define paths
SYSTEM_PATH="/Volumes/Macintosh HD"
DATA_PATH="/Volumes/Macintosh HD - Data"
DSCL_PATH="$DATA_PATH/private/var/db/dslocal/nodes/Default"

# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
create_dir "$DATA_PATH/private/var/db"
create_dir "$DATA_PATH/Users/admin"
create_dir "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings"
create_dir "$SYSTEM_PATH/etc"

# Create admin user
echo -e "${PURPLE}Creating admin user...${NC}"
create_dir "$DSCL_PATH"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" UserShell "/bin/zsh"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" RealName "Admin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" UniqueID "501"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" PrimaryGroupID "20"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/admin" NFSHomeDirectory "/Users/admin"
dscl -f "$DSCL_PATH" localhost -passwd "/Local/Default/Users/admin" "admin123"
dscl -f "$DSCL_PATH" localhost -append "/Local/Default/Groups/admin" GroupMembership "admin"

# Skip Setup Assistant
echo -e "${BLUE}Creating .AppleSetupDone...${NC}"
create_dir "$DATA_PATH/private/var/db"
touch "$DATA_PATH/private/var/db/.AppleSetupDone" 2>/dev/null || true

# Block MDM domains
echo -e "${BLUE}Blocking MDM domains...${NC}"
cat > "$SYSTEM_PATH/etc/hosts" << EOF
127.0.0.1 localhost
::1 localhost
0.0.0.0 deviceenrollment.apple.com
0.0.0.0 mdmenrollment.apple.com
0.0.0.0 iprofiles.apple.com
0.0.0.0 albert.apple.com
0.0.0.0 axm-adm-enroll.apple.com
0.0.0.0 comm.support.apple.com
0.0.0.0 push.apple.com
0.0.0.0 identity.apple.com
EOF

# Remove MDM profiles
echo -e "${BLUE}Removing MDM profiles...${NC}"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles" 2>/dev/null
rm -rf "$DATA_PATH/private/var/db/ConfigurationProfiles" 2>/dev/null
rm -rf "$SYSTEM_PATH/Library/ConfigurationProfiles" 2>/dev/null

# Clear activation record
configPath="$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings"
create_dir "$configPath"
rm -rf "$configPath/.cloudConfigHasActivationRecord" 2>/dev/null
rm -rf "$configPath/.cloudConfigRecordFound" 2>/dev/null
touch "$configPath/.cloudConfigProfileInstalled" 2>/dev/null
touch "$configPath/.cloudConfigRecordNotFound" 2>/dev/null

echo -e "${GREEN}Process completed!${NC}"
echo -e "${BLUE}Admin user created with:${NC}"
echo -e "Username: admin"
echo -e "Password: admin123"
echo -e "\n${GREEN}Please restart your Mac now.${NC}"
echo -e "${BLUE}After restart:${NC}"
echo -e "1. If you see MDM screen, click 'Exit to Recovery', then reboot"
echo -e "2. When you see login screen, use the admin credentials above"
