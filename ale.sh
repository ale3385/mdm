#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}Starting aggressive MDM bypass...${NC}"

# Mount system volume with write permissions
echo -e "${BLUE}Mounting volumes with write permissions...${NC}"
diskutil mount -mountPoint /Volumes/system "Macintosh HD" || true
diskutil mount -mountPoint /Volumes/data "Macintosh HD - Data" || true

# Create directories if they don't exist
mkdir -p "/Volumes/data/private/var/db/dslocal/nodes/Default/users"
mkdir -p "/Volumes/data/private/var/db/dslocal/nodes/Default/groups"
mkdir -p "/Volumes/data/Users/admin"

# Create plist for admin user
echo -e "${BLUE}Creating admin user...${NC}"
cat > "/Volumes/data/private/var/db/dslocal/nodes/Default/users/admin.plist" << EOF
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

# Set proper permissions
chown -R 501:20 "/Volumes/data/Users/admin"
chmod 700 "/Volumes/data/Users/admin"

# Create necessary setup files
echo -e "${BLUE}Creating setup files...${NC}"
touch "/Volumes/data/private/var/db/.AppleSetupDone"
touch "/Volumes/data/var/db/.AppleSetupDone"

# Create files to skip setup
for setup_file in ".AppleSetupDone" ".AppleDiagnosticsSetupDone" ".AppleDesktopSetupDone"; do
    touch "/Volumes/data/private/var/db/$setup_file"
    touch "/Volumes/system/private/var/db/$setup_file"
done

# Block MDM domains in both volumes
echo -e "${BLUE}Blocking MDM domains...${NC}"
for vol in "system" "data"; do
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

# Remove MDM configuration
echo -e "${BLUE}Removing MDM configuration...${NC}"
rm -rf "/Volumes/system/Library/ConfigurationProfiles"
rm -rf "/Volumes/data/Library/ConfigurationProfiles"
rm -rf "/Volumes/system/var/db/ConfigurationProfiles"
rm -rf "/Volumes/data/var/db/ConfigurationProfiles"

# Create autorun script to complete setup after boot
echo -e "${BLUE}Creating autorun script...${NC}"
cat > "/Volumes/data/private/var/root/finishsetup.sh" << EOF
#!/bin/bash
dscl . -passwd /Users/admin "admin123"
rm -f "\$0"
EOF

chmod +x "/Volumes/data/private/var/root/finishsetup.sh"

echo -e "${GREEN}Process completed!${NC}"
echo -e "${BLUE}Important instructions:${NC}"
echo -e "1. Restart your Mac"
echo -e "2. If you see MDM screen, press Command + Q"
echo -e "3. Login credentials:"
echo -e "   Username: admin"
echo -e "   Password: admin123"
echo -e "\n${RED}Note: If you still see setup screen, restart again and:${NC}"
echo -e "1. Boot to Recovery Mode (Command + R)"
echo -e "2. Open Terminal and run this script again"
echo -e "3. After running script, open Disk Utility"
echo -e "4. Click 'Mount' on Macintosh HD if not mounted"
echo -e "5. Then restart"
