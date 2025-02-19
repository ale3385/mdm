#!/bin/bash

# Global constants
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Mount Volumes
echo -e "${BLUE}Mounting volumes...${NC}"
diskutil mount "Macintosh HD" || true
diskutil mount "Macintosh HD - Data" || true

# Define paths
SYSTEM_PATH="/Volumes/Macintosh HD"
DATA_PATH="/Volumes/Macintosh HD - Data"

echo -e "${BLUE}Creating local admin user...${NC}"
# User creation variables
ADMIN_USER="admin"  # You can change this
ADMIN_PASS="1234"   # You can change this
ADMIN_FULL="Admin"  # You can change this

# Create user and user folder
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER" UserShell "/bin/zsh"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER" RealName "$ADMIN_FULL"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER" UniqueID "501"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER" PrimaryGroupID "20"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -create "/Local/Default/Users/$ADMIN_USER" NFSHomeDirectory "/Users/$ADMIN_USER"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -passwd "/Local/Default/Users/$ADMIN_USER" "$ADMIN_PASS"
dscl -f "$DATA_PATH/private/var/db/dslocal/nodes/Default" localhost -append "/Local/Default/Groups/admin" GroupMembership "$ADMIN_USER"

# Create user's home folder
mkdir -p "$DATA_PATH/Users/$ADMIN_USER"
cp -R "$DATA_PATH/Users/Shared"/* "$DATA_PATH/Users/$ADMIN_USER/" 2>/dev/null || true

echo -e "${BLUE}Setting up system files...${NC}"
# Mark system as set up
touch "$DATA_PATH/private/var/db/.AppleSetupDone"
touch "$SYSTEM_PATH/var/db/.AppleSetupDone"

# Create needed folders
mkdir -p "$DATA_PATH/private/var/db/ConfigurationProfiles/Settings"

# Block MDM hosts
echo -e "${BLUE}Blocking MDM hosts...${NC}"
cat >> "$SYSTEM_PATH/etc/hosts" << EOL
0.0.0.0 deviceenrollment.apple.com
0.0.0.0 mdmenrollment.apple.com
0.0.0.0 iprofiles.apple.com
0.0.0.0 albert.apple.com
0.0.0.0 gateway.push.apple.com
0.0.0.0 push.apple.com
0.0.0.0 profile.ess.apple.com
0.0.0.0 setup.icloud.com
0.0.0.0 comm.support.apple.com
0.0.0.0 metrics.apple.com
0.0.0.0 sq-device.apple.com
0.0.0.0 serverstatus.apple.com
0.0.0.0 axm-adm-enroll.apple.com
0.0.0.0 profiles.apple.com
0.0.0.0 identity.apple.com
0.0.0.0 iprofiles.apple.com
EOL

echo -e "${BLUE}Removing MDM profiles and files...${NC}"
# Remove MDM profiles and related files
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles"
rm -rf "$DATA_PATH/private/var/db/ConfigurationProfiles"
rm -rf "$SYSTEM_PATH/Library/LaunchDaemons/com.apple.mdmclient.daemon.plist"
rm -rf "$SYSTEM_PATH/Library/LaunchAgents/com.apple.mdmclient.agent.plist"
rm -rf "$SYSTEM_PATH/Library/Application Support/JAMF"
rm -rf "$SYSTEM_PATH/usr/local/jamf"
rm -rf "$SYSTEM_PATH/var/root/Library/Application Support/com.apple.TCC"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles"

# Disable MDM services
echo -e "${BLUE}Disabling MDM services...${NC}"
touch "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
touch "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
rm -rf "$SYSTEM_PATH/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"

# Set proper permissions
chmod -R 755 "$DATA_PATH/private/var/db/ConfigurationProfiles/Settings"
chown -R root:wheel "$DATA_PATH/private/var/db/ConfigurationProfiles/Settings"

# Create autorun script to disable MDM services after boot
cat > "$SYSTEM_PATH/Library/LaunchDaemons/com.disable.mdm.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.disable.mdm</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>launchctl unload /Library/LaunchDaemons/com.apple.mdmclient.daemon.plist 2>/dev/null; launchctl unload /Library/LaunchAgents/com.apple.mdmclient.agent.plist 2>/dev/null</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOL

chmod 644 "$SYSTEM_PATH/Library/LaunchDaemons/com.disable.mdm.plist"
chown root:wheel "$SYSTEM_PATH/Library/LaunchDaemons/com.disable.mdm.plist"

echo -e "${GREEN}¡Bypass completado!${NC}"
echo -e "${CYAN}Usuario creado:${NC}"
echo -e "  Username: ${GREEN}$ADMIN_USER${NC}"
echo -e "  Password: ${GREEN}$ADMIN_PASS${NC}"
echo -e "\n${YELLOW}Por favor, reinicia el equipo.${NC}"
echo -e "${YELLOW}Después de reiniciar:${NC}"
echo -e "1. Inicia sesión con el usuario creado"
echo -e "2. Si aparece algún prompt de MDM, recházalo"
echo -e "3. Ve a Preferencias del Sistema > Perfiles y verifica que no haya perfiles"
