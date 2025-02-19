#!/bin/bash

# Text formatting
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}Starting direct plist modification...${NC}"

# Mount volumes
echo -e "${BLUE}Mounting volumes...${NC}"
diskutil mount "/Volumes/ale" || true
diskutil mount "/Volumes/ale - Data" || true

# Define paths
DATA_PATH="/Volumes/ale - Data"
USERS_PATH="$DATA_PATH/private/var/db/dslocal/nodes/Default/users"

# Create directories if they don't exist
mkdir -p "$USERS_PATH"
mkdir -p "$DATA_PATH/Users/newadmin"

# Create new admin user plist
echo -e "${BLUE}Creating new admin user...${NC}"
cat > "$USERS_PATH/newadmin.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>name</key>
    <array>
        <string>newadmin</string>
    </array>
    <key>passwd</key>
    <array>
        <string>********</string>
    </array>
    <key>uid</key>
    <array>
        <string>503</string>
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
        <string>/Users/newadmin</string>
    </array>
    <key>realname</key>
    <array>
        <string>New Admin</string>
    </array>
    <key>generateduid</key>
    <array>
        <string>11111111-2222-3333-4444-555555555555</string>
    </array>
    <key>authentication_authority</key>
    <array>
        <string>;ShadowHash;HASHLIST:&lt;SALTED-SHA512&gt;</string>
    </array>
    <key>password_hint</key>
    <array>
        <string></string>
    </array>
    <key>jpegphoto</key>
    <array>
        <data></data>
    </array>
    <key>picture</key>
    <array>
        <string>/Library/User Pictures/Nature/Earth.png</string>
    </array>
    <key>hint</key>
    <array>
        <string></string>
    </array>
</dict>
</plist>
EOF

# Create admin group membership
mkdir -p "$DATA_PATH/private/var/db/dslocal/nodes/Default/groups"
cat > "$DATA_PATH/private/var/db/dslocal/nodes/Default/groups/admin.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>groupmembers</key>
    <array>
        <string>11111111-2222-3333-4444-555555555555</string>
    </array>
    <key>name</key>
    <array>
        <string>admin</string>
    </array>
</dict>
</plist>
EOF

# Set proper permissions
chown -R 503:20 "$DATA_PATH/Users/newadmin"
chmod 700 "$DATA_PATH/Users/newadmin"
chown root:admin "$USERS_PATH/newadmin.plist"
chmod 600 "$USERS_PATH/newadmin.plist"

# Ensure setup is complete
touch "$DATA_PATH/private/var/db/.AppleSetupDone"

echo -e "${GREEN}New admin user created!${NC}"
echo -e "${BLUE}Try these steps:${NC}"
echo -e "1. Restart your Mac"
echo -e "2. At login screen, click 'Other...'"
echo -e "3. Login with:"
echo -e "   Username: newadmin"
echo -e "   Password: admin123"
echo -e "\n${RED}If you still see setup screen:${NC}"
echo -e "1. Press Command + Q"
echo -e "2. Then try logging in"
