#!/bin/bash

# Steam Deck Animation Selector
# This script allows changing boot and suspend animations

# Ensure we're running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Configuration variables
ANIMATION_DIR="/home/deck/custom_animations"
BOOT_ANIMATIONS_DIR="${ANIMATION_DIR}/boot"
SUSPEND_ANIMATIONS_DIR="${ANIMATION_DIR}/suspend"
CONFIG_FILE="${ANIMATION_DIR}/config.conf"

# Steam UI related paths
STEAM_ANIMATIONS_DIR="/home/deck/.steam/root/config/uioverrides/movies"
STEAM_BOOT_FILE="${STEAM_ANIMATIONS_DIR}/deck_startup.webm"
STEAM_SUSPEND_FILE="${STEAM_ANIMATIONS_DIR}/steam_os_suspend.webm"
STEAM_SUSPEND_FROM_THROBBER="${STEAM_ANIMATIONS_DIR}/steam_os_suspend_from_throbber.webm"
STEAM_CSS_FILE="/home/deck/.local/share/Steam/steamui/css/library.css"

# Make sure animation directories exist
for dir in "$ANIMATION_DIR" "$BOOT_ANIMATIONS_DIR" "$SUSPEND_ANIMATIONS_DIR" "$STEAM_ANIMATIONS_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory at $dir"
        mkdir -p "$dir"
        chmod 755 "$dir"
    fi
done

# Make sure the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found. Creating default..."
    echo "# Animation Daemon Configuration" > "$CONFIG_FILE"
    echo "RANDOM_MODE=false" >> "$CONFIG_FILE"
    echo "CURRENT_BOOT=" >> "$CONFIG_FILE"
    echo "CURRENT_SUSPEND=" >> "$CONFIG_FILE"
    echo "USE_DEFAULT_BOOT=true" >> "$CONFIG_FILE"
    echo "USE_DEFAULT_SUSPEND=true" >> "$CONFIG_FILE"
    echo "USE_STEAM_UI_METHOD=true" >> "$CONFIG_FILE"
    echo "USE_STEAM_BOOT_METHOD=true" >> "$CONFIG_FILE"
    echo "STEAM_FULLSCREEN_ENABLED=true" >> "$CONFIG_FILE"
fi

# Source the config file to get current settings
source "$CONFIG_FILE"

# Function to select a boot animation
select_boot_animation() {
    # Check if there are any boot animations
    local animations=()
    local i=1
    
    echo ""
    echo "Available boot animations:"
    echo "0) Default SteamOS animation"
    
    # List all webm files in the boot animations directory
    for anim in "$BOOT_ANIMATIONS_DIR"/*.webm; do
        if [ -f "$anim" ]; then
            local name=$(basename "$anim")
            animations+=("$name")
            echo "$i) $name"
            ((i++))
        fi
    done
    
    echo ""
    read -p "Select a boot animation (0-$((i-1))): " choice
    
    # Validate input
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "$i" ]; then
        if [ "$choice" -eq 0 ]; then
            # Use default
            sed -i "s/^USE_DEFAULT_BOOT=.*/USE_DEFAULT_BOOT=true/" "$CONFIG_FILE"
            sed -i "s/^CURRENT_BOOT=.*/CURRENT_BOOT=/" "$CONFIG_FILE"
            echo "Using default SteamOS boot animation"
        else
            # Use selected animation
            local selected="${animations[$((choice-1))]}"
            sed -i "s/^USE_DEFAULT_BOOT=.*/USE_DEFAULT_BOOT=false/" "$CONFIG_FILE"
            sed -i "s/^CURRENT_BOOT=.*/CURRENT_BOOT=$selected/" "$CONFIG_FILE"
            echo "Selected boot animation: $selected"
        fi
        return 0
    else
        echo "Invalid selection, no changes made"
        return 1
    fi
}

# Function to select a suspend animation
select_suspend_animation() {
    # Check if there are any suspend animations
    local animations=()
    local i=1
    
    echo ""
    echo "Available suspend animations:"
    echo "0) Default SteamOS animation"
    
    # List all webm files in the suspend animations directory
    for anim in "$SUSPEND_ANIMATIONS_DIR"/*.webm; do
        if [ -f "$anim" ]; then
            local name=$(basename "$anim")
            animations+=("$name")
            echo "$i) $name"
            ((i++))
        fi
    done
    
    echo ""
    read -p "Select a suspend animation (0-$((i-1))): " choice
    
    # Validate input
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "$i" ]; then
        if [ "$choice" -eq 0 ]; then
            # Use default
            sed -i "s/^USE_DEFAULT_SUSPEND=.*/USE_DEFAULT_SUSPEND=true/" "$CONFIG_FILE"
            sed -i "s/^CURRENT_SUSPEND=.*/CURRENT_SUSPEND=/" "$CONFIG_FILE"
            echo "Using default SteamOS suspend animation"
        else
            # Use selected animation
            local selected="${animations[$((choice-1))]}"
            sed -i "s/^USE_DEFAULT_SUSPEND=.*/USE_DEFAULT_SUSPEND=false/" "$CONFIG_FILE"
            sed -i "s/^CURRENT_SUSPEND=.*/CURRENT_SUSPEND=$selected/" "$CONFIG_FILE"
            echo "Selected suspend animation: $selected"
        fi
        return 0
    else
        echo "Invalid selection, no changes made"
        return 1
    fi
}

# Function to select boot animation method
select_boot_method() {
    echo ""
    echo "Boot Animation Method:"
    echo "1) System Method (Plymouth) - Works for boot process"
    echo "2) Steam UI Method - Shows deck_startup.webm in Steam UI"
    echo "3) Both Methods (recommended)"
    echo ""
    read -p "Select a boot animation method (1-3): " method_choice
    
    case "$method_choice" in
        1)
            # System Method only
            sed -i "s/^USE_STEAM_BOOT_METHOD=.*/USE_STEAM_BOOT_METHOD=false/" "$CONFIG_FILE"
            echo "Using System Method (Plymouth) for boot animations"
            ;;
        2)
            # Steam UI Method only
            sed -i "s/^USE_STEAM_BOOT_METHOD=.*/USE_STEAM_BOOT_METHOD=true/" "$CONFIG_FILE"
            echo "Using Steam UI Method for boot animations"
            ;;
        3)
            # Both Methods (default)
            sed -i "s/^USE_STEAM_BOOT_METHOD=.*/USE_STEAM_BOOT_METHOD=true/" "$CONFIG_FILE"
            echo "Using both System and Steam UI Methods for boot animations"
            ;;
        *)
            echo "Invalid selection, no changes made"
            return 1
            ;;
    esac
    return 0
}

# Function to select suspend animation method
select_suspend_method() {
    echo ""
    echo "Suspend Animation Method:"
    echo "1) System Method (Plymouth) - Works when suspending from Desktop Mode"
    echo "2) Steam UI Method - Works when suspending from Gaming Mode"
    echo "3) Both Methods (recommended)"
    echo ""
    read -p "Select a suspend animation method (1-3): " method_choice
    
    case "$method_choice" in
        1)
            # System Method only
            sed -i "s/^USE_STEAM_UI_METHOD=.*/USE_STEAM_UI_METHOD=false/" "$CONFIG_FILE"
            echo "Using System Method (Plymouth) for suspend animations"
            ;;
        2)
            # Steam UI Method only
            sed -i "s/^USE_STEAM_UI_METHOD=.*/USE_STEAM_UI_METHOD=true/" "$CONFIG_FILE"
            echo "Using Steam UI Method for suspend animations"
            select_fullscreen_option
            ;;
        3)
            # Both Methods (default)
            sed -i "s/^USE_STEAM_UI_METHOD=.*/USE_STEAM_UI_METHOD=true/" "$CONFIG_FILE"
            echo "Using both System and Steam UI Methods for suspend animations"
            select_fullscreen_option
            ;;
        *)
            echo "Invalid selection, no changes made"
            return 1
            ;;
    esac
    return 0
}

# Function to select fullscreen option for Steam UI suspend
select_fullscreen_option() {
    # Only show if Steam UI method is enabled
    if [[ "$USE_STEAM_UI_METHOD" != "true" ]]; then
        return
    fi
    
    echo ""
    echo "Fullscreen Option for Steam UI Suspend Animation:"
    echo "1) Enable fullscreen (recommended, modifies Steam CSS)"
    echo "2) Use default Steam size (small transparent window in center)"
    echo ""
    read -p "Select fullscreen option (1-2): " fullscreen_choice
    
    case "$fullscreen_choice" in
        1)
            # Enable fullscreen
            sed -i "s/^STEAM_FULLSCREEN_ENABLED=.*/STEAM_FULLSCREEN_ENABLED=true/" "$CONFIG_FILE"
            echo "Fullscreen enabled for Steam UI suspend animations"
            ;;
        2)
            # Default size
            sed -i "s/^STEAM_FULLSCREEN_ENABLED=.*/STEAM_FULLSCREEN_ENABLED=false/" "$CONFIG_FILE"
            echo "Using default size for Steam UI suspend animations"
            ;;
        *)
            echo "Invalid selection, no changes made"
            return 1
            ;;
    esac
    return 0
}

# Function to import new animations
import_animations() {
    echo ""
    echo "Animation Import Menu"
    echo "1) Import boot animations"
    echo "2) Import suspend animations"
    echo "3) Cancel"
    echo ""
    read -p "Select an option (1-3): " import_choice
    
    case "$import_choice" in
        1)
            echo ""
            read -p "Enter the path to the boot animation WebM file: " animation_path
            if [ -f "$animation_path" ]; then
                local filename=$(basename "$animation_path")
                cp "$animation_path" "$BOOT_ANIMATIONS_DIR/"
                echo "Imported $filename to boot animations"
                chown deck:deck "$BOOT_ANIMATIONS_DIR/$filename"
                chmod 644 "$BOOT_ANIMATIONS_DIR/$filename"
            else
                echo "File not found: $animation_path"
            fi
            ;;
        2)
            echo ""
            read -p "Enter the path to the suspend animation WebM file: " animation_path
            if [ -f "$animation_path" ]; then
                local filename=$(basename "$animation_path")
                cp "$animation_path" "$SUSPEND_ANIMATIONS_DIR/"
                echo "Imported $filename to suspend animations"
                chown deck:deck "$SUSPEND_ANIMATIONS_DIR/$filename"
                chmod 644 "$SUSPEND_ANIMATIONS_DIR/$filename"
            else
                echo "File not found: $animation_path"
            fi
            ;;
        3)
            echo "Import cancelled"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to toggle random mode
toggle_random_mode() {
    echo ""
    echo "Random Mode Options:"
    echo "1) Enable random mode (automatic random selection)"
    echo "2) Disable random mode (manual selection)"
    echo ""
    read -p "Select an option (1-2): " random_choice
    
    case "$random_choice" in
        1)
            sed -i "s/^RANDOM_MODE=.*/RANDOM_MODE=true/" "$CONFIG_FILE"
            echo "Random mode enabled - animations will be automatically selected"
            ;;
        2)
            sed -i "s/^RANDOM_MODE=.*/RANDOM_MODE=false/" "$CONFIG_FILE"
            echo "Random mode disabled - you can manually select animations"
            ;;
        *)
            echo "Invalid selection, no changes made"
            return 1
            ;;
    esac
    return 0
}

# Function to reset random history
reset_random_history() {
    local boot_history="${ANIMATION_DIR}/boot_history.txt"
    local suspend_history="${ANIMATION_DIR}/suspend_history.txt"
    
    echo ""
    echo "Reset Random History:"
    echo "1) Reset boot animation history"
    echo "2) Reset suspend animation history"
    echo "3) Reset both histories"
    echo "4) Cancel"
    echo ""
    read -p "Select an option (1-4): " reset_choice
    
    case "$reset_choice" in
        1)
            > "$boot_history"
            echo "Boot animation history reset"
            ;;
        2)
            > "$suspend_history"
            echo "Suspend animation history reset"
            ;;
        3)
            > "$boot_history"
            > "$suspend_history"
            echo "Both animation histories reset"
            ;;
        4)
            echo "Reset cancelled"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to show current settings
show_current_settings() {
    echo ""
    echo "Current Settings:"
    echo "-----------------"
    
    # Show random mode status
    if [[ "$RANDOM_MODE" == "true" ]]; then
        echo "Mode: RANDOM (automatic selection)"
        local boot_count=$(find "$BOOT_ANIMATIONS_DIR" -name "*.webm" 2>/dev/null | wc -l)
        local suspend_count=$(find "$SUSPEND_ANIMATIONS_DIR" -name "*.webm" 2>/dev/null | wc -l)
        echo "Available animations: $boot_count boot, $suspend_count suspend"
        
        # Show current selections if available
        if [[ -n "$CURRENT_BOOT" ]]; then
            echo "Current Boot: $CURRENT_BOOT"
        fi
        if [[ -n "$CURRENT_SUSPEND" ]]; then
            echo "Current Suspend: $CURRENT_SUSPEND"
        fi
    else
        echo "Mode: MANUAL (manual selection)"
        
        if [[ "$USE_DEFAULT_BOOT" == "true" ]]; then
            echo "Boot Animation: Default SteamOS animation"
        else
            if [[ -n "$CURRENT_BOOT" ]]; then
                echo "Boot Animation: $CURRENT_BOOT"
            else
                echo "Boot Animation: None selected"
            fi
        fi
        
        if [[ "$USE_DEFAULT_SUSPEND" == "true" ]]; then
            echo "Suspend Animation: Default SteamOS animation"
        else
            if [[ -n "$CURRENT_SUSPEND" ]]; then
                echo "Suspend Animation: $CURRENT_SUSPEND"
            else
                echo "Suspend Animation: None selected"
            fi
        fi
    fi
    
    echo "Boot Animation Method:"
    if [[ "$USE_STEAM_BOOT_METHOD" == "true" ]]; then
        echo "Using both System and Steam UI boot methods"
    else
        echo "Using System boot method only"
    fi
    
    echo "Suspend Animation Method:"
    if [[ "$USE_STEAM_UI_METHOD" == "true" ]]; then
        if [[ "$STEAM_FULLSCREEN_ENABLED" == "true" ]]; then
            echo "Using System and Steam UI suspend methods (fullscreen enabled)"
        else
            echo "Using System and Steam UI suspend methods (default size)"
        fi
    else
        echo "Using System suspend method only"
    fi
    echo ""
}

# Main menu loop
while true; do
    clear
    echo "========================================"
    echo "    Steam Deck Animation Selector      "
    echo "========================================"
    echo ""
    
    show_current_settings
    
    echo "Menu Options:"
    if [[ "$RANDOM_MODE" == "true" ]]; then
        echo "1) Toggle random mode (currently ENABLED)"
        echo "2) Reset random history"
        echo "3) Animation methods settings"
        echo "4) Import new animations"
        echo "5) Apply changes (restart daemon)"
        echo "6) Exit"
        echo ""
        read -p "Select an option (1-6): " menu_choice
    else
        echo "1) Toggle random mode (currently DISABLED)"
        echo "2) Select boot animation"
        echo "3) Select suspend animation"
        echo "4) Boot animation settings"
        echo "5) Suspend animation settings"
        echo "6) Import new animations"
        echo "7) Apply changes (restart daemon)"
        echo "8) Exit"
        echo ""
        read -p "Select an option (1-8): " menu_choice
    fi
    
    if [[ "$RANDOM_MODE" == "true" ]]; then
        case "$menu_choice" in
            1)
                toggle_random_mode
                ;;
            2)
                reset_random_history
                ;;
            3)
                echo ""
                echo "Animation Methods Settings:"
                echo "1) Change boot animation method"
                echo "2) Change suspend animation method"
                echo "3) Toggle fullscreen for Steam UI animations"
                echo "4) Back to main menu"
                echo ""
                read -p "Select an option (1-4): " method_setting_choice
                
                case "$method_setting_choice" in
                    1)
                        select_boot_method
                        ;;
                    2)
                        select_suspend_method
                        ;;
                    3)
                        select_fullscreen_option
                        ;;
                    4|*)
                        # Back to main menu
                        ;;
                esac
                ;;
            4)
                import_animations
                ;;
            5)
                echo "Restarting animation daemon to apply changes..."
                systemctl restart animation-daemon.service
                echo "Animation daemon restarted"
                ;;
            6)
                echo "Exiting animation selector"
                exit 0
                ;;
            *)
                echo "Invalid option, please try again"
                sleep 2
                ;;
        esac
    else
        case "$menu_choice" in
            1)
                toggle_random_mode
                ;;
            2)
                select_boot_animation
                ;;
            3)
                select_suspend_animation
                ;;
            4)
                echo ""
                echo "Boot Animation Settings:"
                echo "1) Change boot animation method"
                echo "2) Back to main menu"
                echo ""
                read -p "Select an option (1-2): " boot_setting_choice
                
                case "$boot_setting_choice" in
                    1)
                        select_boot_method
                        ;;
                    2|*)
                        # Back to main menu
                        ;;
                esac
                ;;
            5)
                echo ""
                echo "Suspend Animation Settings:"
                echo "1) Change suspend animation method"
                echo "2) Toggle fullscreen for Steam UI animations"
                echo "3) Back to main menu"
                echo ""
                read -p "Select an option (1-3): " suspend_setting_choice
                
                case "$suspend_setting_choice" in
                    1)
                        select_suspend_method
                        ;;
                    2)
                        select_fullscreen_option
                        ;;
                    3|*)
                        # Back to main menu
                        ;;
                esac
                ;;
            6)
                import_animations
                ;;
            7)
                echo "Restarting animation daemon to apply changes..."
                systemctl restart animation-daemon.service
                echo "Animation daemon restarted"
                ;;
            8)
                echo "Exiting animation selector"
                exit 0
                ;;
            *)
                echo "Invalid option, please try again"
                sleep 2
                ;;
        esac
    fi
    
    echo ""
    read -p "Press Enter to continue..."
done