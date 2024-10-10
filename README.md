# mdm



```bash
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

# Checks if a volume with the given name exists
checkVolumeExistence() {
    local volumeLabel="$*"
    diskutil info "$volumeLabel" >/dev/null 2>&1
}

# Returns the name of a volume with the given type
getVolumeName() {
    local volumeType="$1"
    local apfsContainer
    local volumeInfo
    local volumeNameLine
    local volumeName

    apfsContainer=$(diskutil list internal physical | grep 'Container' | awk -F'Container ' '{print $2}' | awk '{print $1}') || handle_error "Failed to get APFS container"
    volumeInfo=$(diskutil ap list "$apfsContainer" | grep -A 5 "($volumeType)") || handle_error "Failed to get volume info"
    volumeNameLine=$(echo "$volumeInfo" | grep 'Name:')
    volumeName=$(echo "$volumeNameLine" | cut -d':' -f2 | cut -d'(' -f1 | xargs)

    echo "$volumeName"
}

# Defines the path to a volume with the given default name and volume type
defineVolumePath() {
    local defaultVolume=$1
    local volumeType=$2
    local volumeName

    if checkVolumeExistence "$defaultVolume"; then
        echo "/Volumes/$defaultVolume"
    else
        volumeName="$(getVolumeName "$volumeType")"
        echo "/Volumes/$volumeName"
    fi
}

# Mounts a volume at the given path
mountVolume() {
    local volumePath=$1

    if [ ! -d "$volumePath" ]; then
        diskutil mount "$volumePath" || handle_error "Failed to mount $volumePath"
    fi
}

# Create user function
createUser() {
    local dscl_path="$1"
    local localUserDirPath="$2"
    local username="$3"
    local fullName="$4"
    local userPassword="$5"
    local defaultUID="$6"
    local dataVolumePath="$7"

    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" || handle_error "Failed to create user"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UserShell "/bin/zsh"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" RealName "$fullName"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" UniqueID "$defaultUID"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" PrimaryGroupID "20"
    mkdir "$dataVolumePath/Users/$username" || handle_error "Failed to create user directory"
    dscl -f "$dscl_path" localhost -create "$localUserDirPath/$username" NFSHomeDirectory "/Users/$username"
    dscl -f "$dscl_path" localhost -passwd "$localUserDirPath/$username" "$userPassword"
    dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
}

# Main menu function
showMenu() {
    PS3='Please enter your choice: '
    options=("Autobypass on Recovery" "Check MDM Enrollment" "Reboot" "Exit")
    select opt in "${options[@]}"; do
        case $opt in
        "Autobypass on Recovery")
            autobypassOnRecovery
            ;;
        "Check MDM Enrollment")
            checkMDMEnrollment
            ;;
        "Reboot")
            echo -e "\n\t${BLUE}Rebooting...${NC}\n"
            reboot
            ;;
        "Exit")
            echo -e "\n\t${BLUE}Exiting...${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option $REPLY${NC}"
            ;;
        esac
    done
}

# Autobypass function
autobypassOnRecovery() {
    echo -e "\n\t${GREEN}Bypass on Recovery${NC}\n"

    # Mount Volumes
    echo -e "${BLUE}Mounting volumes...${NC}"
    systemVolumePath=$(defineVolumePath "$DEFAULT_SYSTEM_VOLUME" "System")
    mountVolume "$systemVolumePath"
    dataVolumePath=$(defineVolumePath "$DEFAULT_DATA_VOLUME" "Data")
    mountVolume "$dataVolumePath"
    echo -e "${GREEN}Volume preparation completed${NC}\n"

    # Create User
    echo -e "${BLUE}Checking user existence${NC}"
    dscl_path="$dataVolumePath/private/var/db/dslocal/nodes/Default"
    localUserDirPath="/Local/Default/Users"
    defaultUID="501"
    if ! dscl -f "$dscl_path" localhost -list "$localUserDirPath" UniqueID | grep -q "\<$defaultUID\>"; then
        echo -e "${CYAN}Create a new user${NC}"
        read -rp "Full name (default: Apple): " fullName
        fullName="${fullName:=Apple}"
        read -rp "Username (default: Apple): " username
        username="${username:=Apple}"
        read -rsp "Password (default: 1234): " userPassword
        userPassword="${userPassword:=1234}"
        echo
        echo -e "\n${BLUE}Creating User${NC}"
        createUser "$dscl_path" "$localUserDirPath" "$username" "$fullName" "$userPassword" "$defaultUID" "$dataVolumePath"
        echo -e "${GREEN}User created${NC}\n"
    else
        echo -e "${BLUE}User already created${NC}\n"
    fi

    # Block MDM hosts
    echo -e "${BLUE}Blocking MDM hosts...${NC}"
    hostsPath="$systemVolumePath/etc/hosts"
    blockedDomains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com")
    for domain in "${blockedDomains[@]}"; do
        echo "0.0.0.0 $domain" >> "$hostsPath" || handle_error "Failed to block $domain"
    done
    echo -e "${GREEN}Successfully blocked hosts${NC}\n"

    # Remove config profiles
    echo -e "${BLUE}Removing config profiles${NC}"
    configProfilesSettingsPath="$systemVolumePath/var/db/ConfigurationProfiles/Settings"
    touch "$dataVolumePath/private/var/db/.AppleSetupDone" || handle_error "Failed to create .AppleSetupDone"
    rm -rf "$configProfilesSettingsPath/.cloudConfigHasActivationRecord"
    rm -rf "$configProfilesSettingsPath/.cloudConfigRecordFound"
    touch "$configProfilesSettingsPath/.cloudConfigProfileInstalled" || handle_error "Failed to create .cloudConfigProfileInstalled"
    touch "$configProfilesSettingsPath/.cloudConfigRecordNotFound" || handle_error "Failed to create .cloudConfigRecordNotFound"
    echo -e "${GREEN}Config profiles removed${NC}\n"

    echo -e "${GREEN}------ Autobypass SUCCESSFUL ------${NC}"
    echo -e "${CYAN}------ Exit Terminal. Reboot Macbook and ENJOY! ------${NC}"
}

# Check MDM Enrollment function
checkMDMEnrollment() {
    if [ ! -f /usr/bin/profiles ]; then
        echo -e "\n\t${RED}Don't use this option in recovery${NC}\n"
        return
    fi

    if ! sudo profiles show -type enrollment >/dev/null 2>&1; then
        echo -e "\n\t${GREEN}Not Enrolled${NC}\n"
    else
        echo -e "\n\t${RED}Enrolled${NC}\n"
    fi
}

# Main script execution
showMenu

```

Aquí están las principales mejoras y sugerencias:

1. Manejo de errores: Se ha añadido una función `handle_error` para manejar errores de manera más consistente y proporcionar mensajes de error más claros.

2. Modularización: Se han separado las principales funcionalidades en funciones independientes (por ejemplo, `createUser`, `autobypassOnRecovery`, `checkMDMEnrollment`), lo que hace que el código sea más fácil de leer y mantener.

3. Mejora en la función de creación de usuarios: Se ha encapsulado la lógica de creación de usuarios en una función separada `createUser`, lo que facilita su reutilización y mantenimiento.

4. Mejora en el manejo de entradas de usuario: Se han simplificado las solicitudes de entrada del usuario y se han mejorado los valores por defecto.

5. Comprobaciones adicionales: Se han añadido más comprobaciones de errores en varias operaciones críticas.

6. Consistencia en el estilo: Se ha mejorado la consistencia en el uso de comillas y en el estilo general del código.

7. Comentarios mejorados: Se han añadido más comentarios para explicar qué hace cada sección del código.

8. Estructura del menú mejorada: Se ha movido la lógica del menú principal a una función separada `showMenu`.

9. Uso de constantes: Se ha mantenido el uso de constantes para valores que no cambian, lo cual es una buena práctica.

10. Manejo de permisos: Aunque no se ha implementado completamente, sería una buena idea añadir comprobaciones de permisos de superusuario al principio del script.

Es importante recordar que este script está diseñado para eludir medidas de seguridad corporativas, lo cual puede tener implicaciones legales y de seguridad significativas. Siempre es recomendable trabajar dentro de las políticas y procedimientos establecidos por tu organización.
