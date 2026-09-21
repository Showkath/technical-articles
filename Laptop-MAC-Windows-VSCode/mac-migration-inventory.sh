
#Run a script to inventory a Mac for migration to another Mac. The script will create a text file with the inventory information.
# Inventory — what is installed/configured on the old Mac.
# Migration checklist — what needs to be installed/configured on the new Mac.
#chmod +x mac-migration-inventory.sh
#./mac-migration-inventory.sh
# It will create: ~/Desktop/Mac-Migration-Inventory.txt
# open ~/Desktop/Mac-Migration-Inventory.txt
# One important point : The inventory will contain things like your Git email, CF target information, environment variables, paths, and possibly configuration details. So before sharing the file with anyone, review it and remove credentials/tokens/secrets if any appear.

#!/bin/bash

OUTPUT="$HOME/Desktop/Mac-Migration-Inventory.txt"

{
echo "======================================================================"
echo "                 MAC MIGRATION INVENTORY"
echo "======================================================================"
echo ""
echo "Generated: $(date)"
echo "User:      $(whoami)"
echo "Hostname:  $(hostname)"
echo "macOS:     $(sw_vers -productVersion)"
echo "Chip:      $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
echo ""
echo "======================================================================"
echo "1. SYSTEM INFORMATION"
echo "======================================================================"
echo ""

sw_vers
echo ""
system_profiler SPHardwareDataType

echo ""
echo "======================================================================"
echo "2. INSTALLED APPLICATIONS"
echo "======================================================================"
echo ""

system_profiler SPApplicationsDataType 2>/dev/null

echo ""
echo "======================================================================"
echo "3. APPLICATIONS IN /Applications"
echo "======================================================================"
echo ""

find /Applications -maxdepth 1 -type d -name "*.app" \
    -exec basename "{}" \; 2>/dev/null | sort

echo ""
echo "======================================================================"
echo "4. HOMEBREW"
echo "======================================================================"
echo ""

if command -v brew >/dev/null 2>&1; then
    echo "Homebrew:"
    brew --version

    echo ""
    echo "--- Homebrew Formulae ---"
    brew list --formula

    echo ""
    echo "--- Homebrew Casks ---"
    brew list --cask

    echo ""
    echo "--- Homebrew Taps ---"
    brew tap

else
    echo "Homebrew is NOT installed."
fi

echo ""
echo "======================================================================"
echo "5. SHELL / TERMINAL"
echo "======================================================================"
echo ""

echo "Default shell:"
echo "$SHELL"

echo ""
echo "Shell version:"
zsh --version 2>/dev/null

echo ""
echo "--- ~/.zshrc ---"
if [ -f "$HOME/.zshrc" ]; then
    cat "$HOME/.zshrc"
else
    echo "No ~/.zshrc found."
fi

echo ""
echo "--- ~/.zprofile ---"
if [ -f "$HOME/.zprofile" ]; then
    cat "$HOME/.zprofile"
else
    echo "No ~/.zprofile found."
fi

echo ""
echo "======================================================================"
echo "6. DEVELOPMENT TOOLS"
echo "======================================================================"

check_command() {
    COMMAND="$1"
    echo ""
    echo "--- $COMMAND ---"

    if command -v "$COMMAND" >/dev/null 2>&1; then
        echo "Path: $(command -v "$COMMAND")"
        "$COMMAND" --version 2>&1 | head -5
    else
        echo "NOT INSTALLED / NOT IN PATH"
    fi
}

check_command git
check_command node
check_command npm
check_command python3
check_command pip3
check_command java
check_command mvn
check_command docker
check_command code
check_command cf
check_command cds
check_command mbt
check_command ui5
check_command xs

echo ""
echo "======================================================================"
echo "7. NODE.JS / NPM"
echo "======================================================================"
echo ""

if command -v node >/dev/null 2>&1; then
    echo "Node:"
    node --version

    echo ""
    echo "NPM:"
    npm --version

    echo ""
    echo "--- Global NPM Packages ---"
    npm list -g --depth=0 2>/dev/null
else
    echo "Node.js is NOT installed."
fi

echo ""
echo "======================================================================"
echo "8. PYTHON"
echo "======================================================================"
echo ""

if command -v python3 >/dev/null 2>&1; then
    python3 --version

    echo ""
    echo "--- Python Packages ---"
    pip3 list 2>/dev/null
else
    echo "Python3 is NOT installed."
fi

echo ""
echo "======================================================================"
echo "9. JAVA / MAVEN"
echo "======================================================================"
echo ""

if command -v java >/dev/null 2>&1; then
    java -version 2>&1
fi

echo ""
echo "--- Installed JDKs ---"
/usr/libexec/java_home -V 2>&1

echo ""
echo "--- Maven ---"
if command -v mvn >/dev/null 2>&1; then
    mvn -version
else
    echo "Maven is NOT installed."
fi

echo ""
echo "======================================================================"
echo "10. CLOUD FOUNDRY / SAP BTP"
echo "======================================================================"
echo ""

if command -v cf >/dev/null 2>&1; then
    echo "--- CF CLI Version ---"
    cf version

    echo ""
    echo "--- CF CLI Plugins ---"
    cf plugins

    echo ""
    echo "--- Current CF Target ---"
    cf target
else
    echo "Cloud Foundry CLI is NOT installed."
fi

echo ""
echo "======================================================================"
echo "11. SAP CAP / UI5 / MTA"
echo "======================================================================"
echo ""

for CMD in cds mbt ui5; do
    echo ""
    echo "--- $CMD ---"

    if command -v "$CMD" >/dev/null 2>&1; then
        echo "Path: $(command -v "$CMD")"
        "$CMD" --version 2>&1 | head -10
    else
        echo "NOT INSTALLED"
    fi
done

echo ""
echo "======================================================================"
echo "12. DOCKER"
echo "======================================================================"
echo ""

if command -v docker >/dev/null 2>&1; then
    docker --version
    echo ""
    echo "--- Docker Context ---"
    docker context ls 2>/dev/null
else
    echo "Docker is NOT installed."
fi

echo ""
echo "======================================================================"
echo "13. GIT CONFIGURATION"
echo "======================================================================"
echo ""

if command -v git >/dev/null 2>&1; then
    echo "--- Git Version ---"
    git --version

    echo ""
    echo "--- Git User ---"
    git config --global user.name 2>/dev/null
    git config --global user.email 2>/dev/null

    echo ""
    echo "--- Git Configuration ---"
    git config --global --list 2>/dev/null
fi

echo ""
echo "======================================================================"
echo "14. VS CODE"
echo "======================================================================"
echo ""

if command -v code >/dev/null 2>&1; then
    echo "--- VS Code Version ---"
    code --version 2>/dev/null

    echo ""
    echo "--- VS Code Extensions ---"
    code --list-extensions 2>/dev/null
else
    echo "VS Code CLI is NOT available."
fi

echo ""
echo "======================================================================"
echo "15. IMPORTANT CONFIGURATION FILES"
echo "======================================================================"
echo ""

for FILE in \
    "$HOME/.zshrc" \
    "$HOME/.zprofile" \
    "$HOME/.bash_profile" \
    "$HOME/.gitconfig" \
    "$HOME/.npmrc"
do
    if [ -f "$FILE" ]; then
        echo "[FOUND] $FILE"
    else
        echo "[NOT FOUND] $FILE"
    fi
done

echo ""
echo "======================================================================"
echo "16. SSH CONFIGURATION"
echo "======================================================================"
echo ""

if [ -d "$HOME/.ssh" ]; then
    echo "SSH directory exists."
    echo ""
    echo "Files:"
    find "$HOME/.ssh" -maxdepth 1 -type f \
        -exec basename "{}" \; 2>/dev/null | sort

    echo ""
    echo "IMPORTANT:"
    echo "Review SSH keys manually before migrating."
    echo "Do NOT copy private keys unless permitted by your security policy."
else
    echo "No ~/.ssh directory found."
fi

echo ""
echo "======================================================================"
echo "17. IMPORTANT DEVELOPMENT DIRECTORIES"
echo "======================================================================"
echo ""

for DIR in \
    "$HOME/.npm" \
    "$HOME/.m2" \
    "$HOME/.docker" \
    "$HOME/.cache" \
    "$HOME/.config"
do
    if [ -d "$DIR" ]; then
        echo "[FOUND] $DIR"
    else
        echo "[NOT FOUND] $DIR"
    fi
done

echo ""
echo "======================================================================"
echo "18. ENVIRONMENT VARIABLES"
echo "======================================================================"
echo ""

env | sort | grep -E \
'^(PATH|JAVA_HOME|M2_HOME|MAVEN_HOME|NODE|NPM|CF_|SAP_|CDS_|UI5_|HOME|SHELL)=' \
2>/dev/null

echo ""
echo "======================================================================"
echo "19. PATH"
echo "======================================================================"
echo ""

echo "$PATH" | tr ':' '\n'

echo ""
echo "======================================================================"
echo "20. LOGIN ITEMS"
echo "======================================================================"
echo ""

osascript -e 'tell application "System Events" to get the name of every login item' \
    2>/dev/null || echo "Unable to retrieve login items."

echo ""
echo "======================================================================"
echo "21. MAC APP STORE / SYSTEM SOFTWARE"
echo "======================================================================"
echo ""

system_profiler SPInstallHistoryDataType 2>/dev/null | head -200

echo ""
echo "======================================================================"
echo "22. QUICK MIGRATION CHECKLIST"
echo "======================================================================"
echo ""

echo "[ ] macOS / Apple ID"
echo "[ ] OneDrive"
echo "[ ] Microsoft Office"
echo "[ ] Outlook"
echo "[ ] Teams"
echo "[ ] VPN"
echo "[ ] Corporate security tools"
echo "[ ] Certificates"
echo "[ ] Git"
echo "[ ] SSH"
echo "[ ] Homebrew"
echo "[ ] Node.js / npm"
echo "[ ] Python"
echo "[ ] Java / JDK"
echo "[ ] Maven"
echo "[ ] Docker"
echo "[ ] Cloud Foundry CLI"
echo "[ ] CF CLI plugins"
echo "[ ] SAP CAP CLI"
echo "[ ] MTA Build Tool"
echo "[ ] UI5 CLI"
echo "[ ] VS Code"
echo "[ ] VS Code extensions"
echo "[ ] Postman"
echo "[ ] Git configuration"
echo "[ ] Shell configuration"
echo "[ ] Environment variables"


#Enhance the script slightly before you run it.
echo ""
echo "======================================================================"
echo "23. SAP BTP/BAIP CAP PROJECTS"
echo "======================================================================"
echo ""

find "$HOME" \
    -type f \
    \( -name "mta.yaml" -o -name "package.json" \) \
    -not -path "$HOME/Library/*" \
    -not -path "$HOME/.npm/*" \
    -not -path "$HOME/.cache/*" \
    2>/dev/null | head -500

echo ""
echo "======================================================================"
echo "                    END OF INVENTORY"
echo "======================================================================"

} > "$OUTPUT"

echo ""
echo "Inventory completed."
echo ""
echo "Output file:"
echo "$OUTPUT"
echo ""
echo "You can open it with:"
echo "open \"$OUTPUT\""