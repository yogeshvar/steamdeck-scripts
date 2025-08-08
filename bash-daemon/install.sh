#!/bin/bash

# Steam Deck Custom Animation Daemon Installer - AUTOMATIC MODE
# This script automatically installs the daemon with random animation selection

# Ensure we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Installation directories
INSTALL_DIR="/home/deck/animation-daemon"
SERVICE_FILE="/etc/systemd/system/animation-daemon.service"
ANIMATION_DIR="/home/deck/custom_animations"
BOOT_ANIMATIONS_DIR="${ANIMATION_DIR}/boot"
SUSPEND_ANIMATIONS_DIR="${ANIMATION_DIR}/suspend"
CONFIG_FILE="${ANIMATION_DIR}/config.conf"
SCRIPT_DIR="$(dirname "$0")"

# Steam UI related paths
STEAM_ANIMATIONS_DIR="/home/deck/.steam/root/config/uioverrides/movies"
STEAM_BOOT_FILE="${STEAM_ANIMATIONS_DIR}/deck_startup.webm"
STEAM_SUSPEND_FILE="${STEAM_ANIMATIONS_DIR}/steam_os_suspend.webm"
STEAM_SUSPEND_FROM_THROBBER="${STEAM_ANIMATIONS_DIR}/steam_os_suspend_from_throbber.webm"
STEAM_CSS_FILE="/home/deck/.local/share/Steam/steamui/css/library.css"

echo "========================================"
echo "Steam Deck Animation Daemon - AUTO MODE"
echo "========================================"
echo ""
echo "Installing automatic random animation daemon..."

# Create installation directories
echo "Creating installation directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$ANIMATION_DIR"
mkdir -p "$BOOT_ANIMATIONS_DIR"
mkdir -p "$SUSPEND_ANIMATIONS_DIR"
mkdir -p "$STEAM_ANIMATIONS_DIR"

# Copy boot animations if they exist
if [ -d "${SCRIPT_DIR}/boot" ]; then
    echo "Copying boot animations..."
    boot_count=$(find "${SCRIPT_DIR}/boot" -name "*.webm" | wc -l)
    echo "Found $boot_count boot animations"
    cp -r "${SCRIPT_DIR}/boot/"* "$BOOT_ANIMATIONS_DIR/" 2>/dev/null || true
fi

# Copy suspend animations if they exist
if [ -d "${SCRIPT_DIR}/suspend" ]; then
    echo "Copying suspend animations..."
    suspend_count=$(find "${SCRIPT_DIR}/suspend" -name "*.webm" | wc -l)
    echo "Found $suspend_count suspend animations"
    cp -r "${SCRIPT_DIR}/suspend/"* "$SUSPEND_ANIMATIONS_DIR/" 2>/dev/null || true
fi

# If no suspend animations exist, copy boot animations to suspend folder
if [ ! -d "${SCRIPT_DIR}/suspend" ] && [ -d "${SCRIPT_DIR}/boot" ]; then
    echo "No suspend animations found, copying boot animations for use as suspend animations..."
    cp -r "${SCRIPT_DIR}/boot/"* "$SUSPEND_ANIMATIONS_DIR/" 2>/dev/null || true
fi

# Copy daemon scripts
echo "Installing daemon scripts..."
cp "${SCRIPT_DIR}/animation-daemon.sh" "$INSTALL_DIR/"
cp "${SCRIPT_DIR}/select-animation.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/animation-daemon.sh" "$INSTALL_DIR/select-animation.sh"

# Set appropriate permissions
chown -R deck:deck "$INSTALL_DIR"
chown -R deck:deck "$ANIMATION_DIR"
chown -R deck:deck "$STEAM_ANIMATIONS_DIR"
chmod 755 "$INSTALL_DIR"
chmod 755 "$ANIMATION_DIR"
chmod 755 "$BOOT_ANIMATIONS_DIR"
chmod 755 "$SUSPEND_ANIMATIONS_DIR"
chmod 755 "$STEAM_ANIMATIONS_DIR"

# Copy service file
echo "Installing systemd service..."
cp "${SCRIPT_DIR}/animation-daemon.service" "$SERVICE_FILE"
chmod 644 "$SERVICE_FILE"

# Create automatic configuration - no user interaction needed
echo "Configuring automatic random mode..."
echo "# Animation Daemon Configuration - RANDOM MODE" > "$CONFIG_FILE"
echo "RANDOM_MODE=true" >> "$CONFIG_FILE"
echo "USE_STEAM_UI_METHOD=true" >> "$CONFIG_FILE"
echo "USE_STEAM_BOOT_METHOD=true" >> "$CONFIG_FILE"
echo "STEAM_FULLSCREEN_ENABLED=true" >> "$CONFIG_FILE"
echo "CURRENT_BOOT=" >> "$CONFIG_FILE"
echo "CURRENT_SUSPEND=" >> "$CONFIG_FILE"

# Set proper ownership for config
chown deck:deck "$CONFIG_FILE"

# Count available animations
boot_animations=$(find "$BOOT_ANIMATIONS_DIR" -name "*.webm" 2>/dev/null | wc -l)
suspend_animations=$(find "$SUSPEND_ANIMATIONS_DIR" -name "*.webm" 2>/dev/null | wc -l)

echo ""
echo "Configuration Summary:"
echo "- Boot animations: $boot_animations"
echo "- Suspend animations: $suspend_animations"
echo "- Random mode: ENABLED"
echo "- Both system and Steam UI animations: ENABLED"
echo "- Fullscreen suspend animations: ENABLED"
echo ""

# Enable and start the service
echo "Enabling and starting the animation daemon..."
systemctl daemon-reload
systemctl enable animation-daemon.service
systemctl start animation-daemon.service

# Check if service started successfully
sleep 2
if systemctl is-active --quiet animation-daemon.service; then
    service_status="RUNNING"
else
    service_status="FAILED"
fi

echo ""
echo "=========================================="
echo "Steam Deck Animation Daemon Installed!"
echo "=========================================="
echo ""
echo "✓ Installation: Complete"
echo "✓ Service Status: $service_status"
echo "✓ Random Mode: Active"
echo ""
echo "Your animations will now randomly change on:"
echo "• Boot/Restart"
echo "• Wake from suspend"
echo "• Each suspend event"
echo ""
echo "The daemon will:"
echo "• Never show the same animation twice in a row"
echo "• Cycle through all your animations without repeating"
echo "• Apply animations to both system and Steam UI"
echo "• Show suspend animations in fullscreen"
echo ""
echo "Animation locations:"
echo "• Boot animations: $BOOT_ANIMATIONS_DIR"
echo "• Suspend animations: $SUSPEND_ANIMATIONS_DIR"
echo ""
echo "Management:"
echo "• Check logs: cat /tmp/animation-daemon.log"
echo "• Check status: systemctl status animation-daemon.service"
echo "• Manual control: sudo ${INSTALL_DIR}/select-animation.sh"
echo "• Uninstall: sudo bash uninstall.sh"
echo ""
echo "Enjoy your random custom animations!"