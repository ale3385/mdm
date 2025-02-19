#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}Starting password reset process...${NC}"

# Mount volumes
echo -e "${BLUE}Mounting volumes...${NC}"
diskutil mount "/Volumes/ale" || true
diskutil mount "/Volumes/ale - Data" || true

# Define paths
DATA_PATH="/Volumes/ale - Data"
DSCL_PATH="$DATA_PATH/private/var/db/dslocal/nodes/Default"

# Reset password
echo -e "${BLUE}Resetting password...${NC}"
dscl -f "$DSCL_PATH" localhost -passwd "/Local/Default/Users/admin" "1234"
dscl -f "$DSCL_PATH" localhost -passwd "/Local/Default/Users/Administrator" "1234"

# Create new admin user as backup
echo -e "${BLUE}Creating backup admin user...${NC}"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin" UserShell "/bin/zsh"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin" RealName "Local Admin"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin" UniqueID "502"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin" PrimaryGroupID "20"
dscl -f "$DSCL_PATH" localhost -create "/Local/Default/Users/localadmin" NFSHomeDirectory "/Users/localadmin"
dscl -f "$DSCL_PATH" localhost -passwd "/Local/Default/Users/localadmin" "admin123"
dscl -f "$DSCL_PATH" localhost -append "/Local/Default/Groups/admin" GroupMembership "localadmin"

# Create home directory for new user
mkdir -p "$DATA_PATH/Users/localadmin"
chown -R 502:20 "$DATA_PATH/Users/localadmin"
chmod 700 "$DATA_PATH/Users/localadmin"

# Ensure setup is done
touch "$DATA_PATH/private/var/db/.AppleSetupDone"

echo -e "${GREEN}Password reset complete!${NC}"
echo -e "${BLUE}You can now try to login with either:${NC}"
echo -e "1. Username: admin or Administrator"
echo -e "   Password: 1234"
echo -e "\n2. Backup account:"
echo -e "   Username: localadmin"
echo -e "   Password: admin123"
echo -e "\n${RED}Important:${NC} After restart, if you still see the setup screen:"
echo -e "1. Press Command + Q to skip"
echo -e "2. Try both sets of credentials above"
