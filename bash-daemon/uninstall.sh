#!/bin/bash

# Steam Deck Custom Animation Daemon Uninstaller
# This script removes the custom animation daemon service

# Ensure we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Installation directories
INSTALL_DIR="/home/deck/animation-daemon"
SERVICE_FILE="/etc/systemd/system/animation-daemon.service"
ANIMATION_DIR="/home/deck/custom_animations"

# Plymouth system animations
DEFAULT_BOOT="/usr/share/plymouth/themes/steamos/steamos.webm"
DEFAULT_SUSPEND="/usr/share/plymouth/themes/steamos/suspend.webm"

# Steam UI animations directory
STEAM_ANIMATIONS_DIR="/home/deck/.steam/root/config/uioverrides/movies"

# Steam UI boot animation
STEAM_BOOT_FILE="${STEAM_ANIMATIONS_DIR}/deck_startup.webm"

# Steam UI suspend animations
STEAM_SUSPEND_FILE="${STEAM_ANIMATIONS_DIR}/steam_os_suspend.webm"
STEAM_SUSPEND_FROM_THROBBER="${STEAM_ANIMATIONS_DIR}/steam_os_suspend_from_throbber.webm"

# Steam CSS file for fullscreen support
STEAM_CSS_FILE="/home/deck/.local/share/Steam/steamui/css/library.css"

# Ask for confirmation
echo "This will uninstall the Steam Deck Animation Daemon."
echo "All custom animations will be preserved in $ANIMATION_DIR."
read -p "Continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstall cancelled."
    exit 1
fi

# Stop and disable the service
echo "Stopping and disabling the service..."
systemctl stop animation-daemon.service
systemctl disable animation-daemon.service
systemctl daemon-reload

# Remove service file
echo "Removing systemd service..."
if [ -f "$SERVICE_FILE" ]; then
    rm "$SERVICE_FILE"
fi

# Restore original Plymouth animations if backups exist
echo "Restoring original system animations..."
if [ -f "${DEFAULT_BOOT}.original" ]; then
    cp "${DEFAULT_BOOT}.original" "$DEFAULT_BOOT"
    echo "Restored original boot animation."
fi

if [ -f "${DEFAULT_SUSPEND}.original" ]; then
    cp "${DEFAULT_SUSPEND}.original" "$DEFAULT_SUSPEND"
    echo "Restored original suspend animation."
fi

# Restore Steam UI boot animation if backup exists
echo "Restoring Steam UI boot animation..."
if [ -f "${STEAM_BOOT_FILE}.original" ]; then
    cp "${STEAM_BOOT_FILE}.original" "$STEAM_BOOT_FILE"
    echo "Restored original Steam UI boot animation."
    # Set proper ownership
    chown deck:deck "$STEAM_BOOT_FILE"
elif [ -f "$STEAM_BOOT_FILE" ]; then
    # If no backup exists but file exists, remove the custom animation
    rm "$STEAM_BOOT_FILE"
    echo "Removed custom Steam UI boot animation."
fi

# Restore Steam UI suspend animations if backups exist
echo "Restoring Steam UI suspend animations..."
for file in "$STEAM_SUSPEND_FILE" "$STEAM_SUSPEND_FROM_THROBBER"; do
    if [ -f "${file}.original" ]; then
        cp "${file}.original" "$file"
        echo "Restored original Steam UI animation: $file"
        # Set proper ownership
        chown deck:deck "$file"
    elif [ -f "$file" ]; then
        # If no backup exists but file exists, remove the custom animation
        rm "$file"
        echo "Removed custom Steam UI animation: $file"
    fi
done

# Restore Steam CSS file if backup exists
echo "Restoring Steam CSS file..."
if [ -f "${STEAM_CSS_FILE}.original" ]; then
    cp "${STEAM_CSS_FILE}.original" "$STEAM_CSS_FILE"
    echo "Restored original Steam CSS file."
    # Set proper ownership
    chown deck:deck "$STEAM_CSS_FILE"
fi

# Remove installation directory
echo "Removing installation files..."
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi

# Ask if user wants to remove animation files
echo ""
echo "Do you want to keep your custom animations?"
echo "1) Keep all animations (recommended)"
echo "2) Remove all animations"
echo "3) Keep only boot animations"
echo "4) Keep only suspend animations"
read -p "Select an option (1-4): " remove_choice

case "$remove_choice" in
    2)
        echo "Removing all custom animations..."
        rm -rf "$ANIMATION_DIR"
        ;;
    3)
        echo "Keeping boot animations, removing others..."
        mkdir -p "${ANIMATION_DIR}_temp/boot"
        cp -r "${ANIMATION_DIR}/boot/"* "${ANIMATION_DIR}_temp/boot/" 2>/dev/null || true
        rm -rf "$ANIMATION_DIR"
        mv "${ANIMATION_DIR}_temp" "$ANIMATION_DIR"
        chown -R deck:deck "$ANIMATION_DIR"
        ;;
    4)
        echo "Keeping suspend animations, removing others..."
        mkdir -p "${ANIMATION_DIR}_temp/suspend"
        cp -r "${ANIMATION_DIR}/suspend/"* "${ANIMATION_DIR}_temp/suspend/" 2>/dev/null || true
        rm -rf "$ANIMATION_DIR"
        mv "${ANIMATION_DIR}_temp" "$ANIMATION_DIR"
        chown -R deck:deck "$ANIMATION_DIR"
        ;;
    *)
        echo "Keeping all custom animations."
        ;;
esac

echo ""
echo "=========================================="
echo "Steam Deck Animation Daemon Uninstalled!"
echo "=========================================="
echo ""
echo "Original system and Steam UI animations have been restored."
if [ -d "$ANIMATION_DIR" ]; then
    echo "Your custom animations are preserved in: $ANIMATION_DIR"
    echo "You can manually remove them with: rm -rf $ANIMATION_DIR"
fi
echo ""
echo "To reinstall, run install.sh again."