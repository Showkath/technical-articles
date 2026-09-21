#!/bin/bash

# ============================================================================
# Mac-Migration-Install-Commands.sh
# ============================================================================
# Purpose:
#   Prepare a new Mac for a development environment, with emphasis on
#   SAP BTP / Cloud Foundry / CAP / Node.js / UI5 / MTA development.
#
# IMPORTANT:
#   - Review this script before running it (Don't run it blindly yet. In particular, check the Java/JDK section against the JDK version your current CAP/BTP projects require. Also compare your old CF CLI plugins, Node version, npm global packages, and VS Code extensions before installing everything.)
#   - It intentionally does NOT copy credentials, SSH private keys, tokens,
#     certificates, or CF login sessions from the old Mac.
#   - Some corporate applications (VPN, security agents, endpoint tools)
#     should be installed using your company's approved process.
#
# Usage:
#   chmod +x Mac-Migration-Install-Commands.sh
#   ./Mac-Migration-Install-Commands.sh
#
# Optional:
#   If you have the old inventory file:
#     ./Mac-Migration-Install-Commands.sh ~/Desktop/Mac-Migration-Inventory.txt
#
# The script is designed to be re-runnable. Existing packages are skipped.
# ============================================================================

set -u

INVENTORY="${1:-$HOME/Desktop/Mac-Migration-Inventory.txt}"
LOG="$HOME/Desktop/Mac-Migration-Install-Log.txt"

exec > >(tee -a "$LOG") 2>&1

echo ""
echo "======================================================================"
echo "                 MAC MIGRATION INSTALLER"
echo "======================================================================"
echo "Started:   $(date)"
echo "Mac:       $(hostname)"
echo "macOS:     $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo "Inventory: $INVENTORY"
echo "Log:       $LOG"
echo "======================================================================"
echo ""

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

section() {
    echo ""
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    echo ""
}

install_brew_formula() {
    local pkg="$1"
    if brew list --formula "$pkg" >/dev/null 2>&1; then
        echo "[SKIP] Homebrew formula already installed: $pkg"
    else
        echo "[INSTALL] Homebrew formula: $pkg"
        brew install "$pkg"
    fi
}

install_brew_cask() {
    local pkg="$1"
    if brew list --cask "$pkg" >/dev/null 2>&1; then
        echo "[SKIP] Homebrew cask already installed: $pkg"
    else
        echo "[INSTALL] Homebrew cask: $pkg"
        brew install --cask "$pkg"
    fi
}

# --------------------------------------------------------------------------
# 1. Basic checks
# --------------------------------------------------------------------------

section "1. BASIC CHECKS"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This script is intended for macOS."
    exit 1
fi

ARCH="$(uname -m)"

if [[ "$ARCH" == "arm64" ]]; then
    echo "Apple Silicon Mac detected."
else
    echo "Intel Mac detected."
fi

echo "macOS:"
sw_vers

# --------------------------------------------------------------------------
# 2. Xcode Command Line Tools
# --------------------------------------------------------------------------

section "2. XCODE COMMAND LINE TOOLS"

if xcode-select -p >/dev/null 2>&1; then
    echo "[OK] Xcode Command Line Tools:"
    xcode-select -p
else
    echo "[ACTION] Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    echo "If macOS displayed an installation dialog, complete it and"
    echo "re-run this script afterward."
fi

# --------------------------------------------------------------------------
# 3. Homebrew
# --------------------------------------------------------------------------

section "3. HOMEBREW"

if command_exists brew; then
    echo "[OK] Homebrew already installed:"
    brew --version
else
    echo "[INSTALL] Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$ARCH" == "arm64" ]]; then
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            fi
        fi
    else
        if [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
            if ! grep -q '/usr/local/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
            fi
        fi
    fi

    if ! command_exists brew; then
        echo "ERROR: Homebrew is not available yet."
        echo "Open a new Terminal window and re-run this script."
        exit 1
    fi
fi

brew update

# --------------------------------------------------------------------------
# 4. Core command-line tools
# --------------------------------------------------------------------------

section "4. CORE DEVELOPMENT TOOLS"

FORMULAE=(
    git
    wget
    jq
    yq
    tree
    openssl
    shellcheck
)

for pkg in "${FORMULAE[@]}"; do
    install_brew_formula "$pkg"
done

# --------------------------------------------------------------------------
# 5. Node.js
# --------------------------------------------------------------------------

section "5. NODE.JS / NPM"

# Use Homebrew Node unless the old inventory explicitly shows another
# version-management strategy. If you use nvm/asdf on the old Mac, install
# that separately and use your required Node version instead.
install_brew_formula node

echo ""
echo "Node:"
node --version

echo "npm:"
npm --version

# --------------------------------------------------------------------------
# 6. SAP BTP / CAP / UI5 / MTA tooling
# --------------------------------------------------------------------------

section "6. SAP BTP / CAP / UI5 / MTA"

echo "Installing SAP CAP Development Kit..."
npm install -g @sap/cds-dk

echo "Installing UI5 CLI..."
npm install -g @ui5/cli

echo "Installing MTA Build Tool..."
npm install -g mbt

echo ""
echo "--- Installed SAP tooling ---"

if command_exists cds; then
    echo "CAP:"
    cds --version
else
    echo "WARNING: cds command not available yet."
fi

if command_exists ui5; then
    echo ""
    echo "UI5:"
    ui5 --version
else
    echo "WARNING: ui5 command not available yet."
fi

if command_exists mbt; then
    echo ""
    echo "MTA:"
    mbt --version
else
    echo "WARNING: mbt command not available yet."
fi

# --------------------------------------------------------------------------
# 7. Cloud Foundry CLI
# --------------------------------------------------------------------------

section "7. CLOUD FOUNDRY CLI"

# Homebrew's cloudfoundry-cli is the standard CLI package.
install_brew_formula cloudfoundry-cli

echo ""
echo "CF CLI:"
cf version

echo ""
echo "NOTE:"
echo "CF CLI plugins from the old Mac are intentionally NOT blindly installed."
echo "Review the old inventory and install only the plugins you actually need."
echo ""
echo "To inspect plugins on the old Mac:"
echo "  cf plugins"

# --------------------------------------------------------------------------
# 8. Java / Maven
# --------------------------------------------------------------------------

section "8. JAVA / JDK / MAVEN"

# Temurin is a commonly used OpenJDK distribution. If your company/project
# requires a specific SAP/Oracle JDK, install that approved distribution
# instead of this default.
install_brew_formula --cask temurin

install_brew_formula maven

echo ""
echo "Java:"
java -version 2>&1 || true

echo ""
echo "Maven:"
mvn -version || true

echo ""
echo "Installed JDKs:"
/usr/libexec/java_home -V 2>&1 || true

# --------------------------------------------------------------------------
# 9. Python
# --------------------------------------------------------------------------

section "9. PYTHON"

install_brew_formula python

echo ""
python3 --version || true
pip3 --version || true

# --------------------------------------------------------------------------
# 10. Docker
# --------------------------------------------------------------------------

section "10. DOCKER"

install_brew_cask docker

echo ""
echo "Docker Desktop has been installed if it was not already present."
echo "Open Docker Desktop once and complete its initial setup."

if command_exists docker; then
    docker --version
else
    echo "docker command will be available after Docker Desktop starts."
fi

# --------------------------------------------------------------------------
# 11. Visual Studio Code
# --------------------------------------------------------------------------

section "11. VISUAL STUDIO CODE"

install_brew_cask visual-studio-code

echo ""
echo "VS Code installed."
echo ""
echo "IMPORTANT:"
echo "The old inventory contains your VS Code extensions."
echo "This script does not blindly install every extension."
echo "Review the old inventory and install approved extensions on the new Mac."
echo ""
echo "If you have a saved extension list:"
echo "  cat ~/Desktop/vscode-extensions.txt | xargs -n 1 code --install-extension"

# --------------------------------------------------------------------------
# 12. Common developer applications
# --------------------------------------------------------------------------

section "12. COMMON DEVELOPER APPLICATIONS"

# These are intentionally limited to common development tools.
# Add/remove applications according to your old Mac inventory and company policy.

CASKS=(
    iterm2
    postman
    microsoft-teams
    onedrive
)

for pkg in "${CASKS[@]}"; do
    install_brew_cask "$pkg"
done

# --------------------------------------------------------------------------
# 13. Git configuration reminder
# --------------------------------------------------------------------------

section "13. GIT CONFIGURATION"

if command_exists git; then
    echo "Git:"
    git --version
    echo ""
    echo "Current global Git configuration:"
    git config --global --list 2>/dev/null || true
    echo ""
    echo "If the old Mac had a custom Git configuration, review:"
    echo "  ~/.gitconfig"
    echo ""
    echo "Do NOT blindly copy credential helpers or tokens."
fi

# --------------------------------------------------------------------------
# 14. Shell configuration
# --------------------------------------------------------------------------

section "14. SHELL CONFIGURATION"

echo "Default shell:"
echo "$SHELL"

echo ""
echo "Files to review from the old Mac:"
echo "  ~/.zshrc"
echo "  ~/.zprofile"
echo "  ~/.bash_profile"
echo "  ~/.gitconfig"
echo "  ~/.npmrc"

echo ""
echo "IMPORTANT:"
echo "Do not blindly copy ~/.zshrc because it may contain secrets,"
echo "company URLs, tokens, or machine-specific paths."

# --------------------------------------------------------------------------
# 15. SSH
# --------------------------------------------------------------------------

section "15. SSH"

echo "SSH directory:"
if [[ -d "$HOME/.ssh" ]]; then
    echo "[FOUND] $HOME/.ssh"
else
    echo "[NOT FOUND] $HOME/.ssh"
fi

echo ""
echo "SSH keys should be handled according to your corporate security policy."
echo "Do not blindly copy private keys from the old Mac."

# --------------------------------------------------------------------------
# 16. Certificates / Keychain reminder
# --------------------------------------------------------------------------

section "16. CERTIFICATES / KEYCHAIN"

echo "No automatic certificate migration is performed."
echo ""
echo "Review the old Mac for:"
echo "  - Corporate certificates"
echo "  - Client certificates"
echo "  - Developer certificates"
echo "  - Java keystores"
echo "  - SAP/BTP-related certificates"
echo ""
echo "Use your corporate-approved process to reissue/import certificates."

# --------------------------------------------------------------------------
# 17. OneDrive
# --------------------------------------------------------------------------

section "17. ONEDRIVE"

echo "OneDrive has been installed as a cask if it was not already installed."
echo ""
echo "Open OneDrive and sign in with your corporate account."
echo "Allow synchronization to complete before deleting/retiring the old Mac."

# --------------------------------------------------------------------------
# 18. Inventory review
# --------------------------------------------------------------------------

section "18. OLD MAC INVENTORY REVIEW"

if [[ -f "$INVENTORY" ]]; then
    echo "[FOUND] Old inventory:"
    echo "$INVENTORY"
    echo ""
    echo "The following applications/tooling should be compared manually"
    echo "against the old inventory:"
    echo ""
    echo "  - Corporate VPN"
    echo "  - Endpoint/security agents"
    echo "  - SAP-specific applications"
    echo "  - Microsoft applications"
    echo "  - Browser extensions"
    echo "  - VS Code extensions"
    echo "  - CF CLI plugins"
    echo "  - Special Java/JDK versions"
    echo "  - Node version manager (nvm/asdf/etc.)"
    echo "  - npm global packages"
    echo "  - Custom shell tools"
else
    echo "[INFO] Old inventory not found at:"
    echo "$INVENTORY"
    echo ""
    echo "Run your inventory script on the old Mac first, then use this file"
    echo "as the migration reference."
fi

# --------------------------------------------------------------------------
# 19. BTP / CAP verification
# --------------------------------------------------------------------------

section "19. SAP BTP / CAP VERIFICATION"

echo "Checking key commands..."
echo ""

for CMD in node npm git cf cds mbt ui5 java mvn python3 docker; do
    if command_exists "$CMD"; then
        echo "[OK] $CMD -> $(command -v "$CMD")"
    else
        echo "[MISSING] $CMD"
    fi
done

echo ""
echo "--- Versions ---"

echo ""
echo "Node:"
node --version 2>/dev/null || true

echo ""
echo "npm:"
npm --version 2>/dev/null || true

echo ""
echo "CAP:"
cds --version 2>/dev/null || true

echo ""
echo "UI5:"
ui5 --version 2>/dev/null || true

echo ""
echo "MTA:"
mbt --version 2>/dev/null || true

echo ""
echo "Cloud Foundry:"
cf version 2>/dev/null || true

echo ""
echo "Java:"
java -version 2>&1 || true

echo ""
echo "Maven:"
mvn -version 2>/dev/null || true

# --------------------------------------------------------------------------
# 20. Final checklist
# --------------------------------------------------------------------------

section "20. FINAL MIGRATION CHECKLIST"

cat <<'CHECKLIST'
[ ] macOS updated
[ ] Apple ID / corporate account configured
[ ] OneDrive installed and synchronized
[ ] Microsoft Office / Outlook installed
[ ] Microsoft Teams installed
[ ] Corporate VPN installed
[ ] Corporate security/endpoint tools installed
[ ] Certificates imported/reissued as required

[ ] Homebrew installed
[ ] Git installed
[ ] Git configuration reviewed
[ ] SSH configuration reviewed
[ ] Node.js installed
[ ] npm installed
[ ] CAP CDS CLI installed
[ ] UI5 CLI installed
[ ] MTA Build Tool installed
[ ] Cloud Foundry CLI installed
[ ] Required CF CLI plugins installed
[ ] Python installed
[ ] Java/JDK installed
[ ] Required JDK version verified
[ ] Maven installed
[ ] Docker Desktop installed and started

[ ] VS Code installed
[ ] VS Code CLI enabled
[ ] Required VS Code extensions installed
[ ] Postman installed
[ ] iTerm2 installed (if required)

[ ] ~/.zshrc reviewed
[ ] ~/.zprofile reviewed
[ ] ~/.gitconfig reviewed
[ ] ~/.npmrc reviewed
[ ] PATH verified
[ ] JAVA_HOME verified
[ ] npm configuration verified

[ ] CAP projects open successfully
[ ] npm install works in CAP projects
[ ] cds build works
[ ] mbt build works
[ ] UI5 build works where applicable
[ ] CF login works
[ ] CF target/organization/space verified
[ ] BTP deployment tested
[ ] Git clone/push/pull tested
[ ] Docker works

[ ] Old Mac data verified
[ ] OneDrive sync verified
[ ] Important repositories verified
[ ] Important local files verified
[ ] Old Mac retained until migration is fully validated
CHECKLIST

# --------------------------------------------------------------------------
# 21. Finish
# --------------------------------------------------------------------------

section "INSTALLATION COMPLETE"

echo "The installation/preparation process has completed."
echo ""
echo "Log file:"
echo "$LOG"
echo ""
echo "Next recommended steps:"
echo "1. Review the migration checklist above."
echo "2. Compare the old Mac inventory with the new Mac."
echo "3. Install any corporate/SAP-specific software separately."
echo "4. Restore/recreate approved SSH keys and certificates."
echo "5. Verify Node/CAP/UI5/MTA/CF versions against your projects."
echo "6. Test a real CAP build and BTP deployment."
echo ""
echo "IMPORTANT:"
echo "Do not retire or wipe the old Mac until your repositories,"
echo "OneDrive, certificates, credentials, and BTP development workflow"
echo "have been successfully validated on the new Mac."
echo ""
echo "Completed: $(date)"
echo "======================================================================"
