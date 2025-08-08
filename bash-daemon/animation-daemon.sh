#!/bin/bash

# Steam Deck Custom Animation Daemon - Random Mode
# This script automatically cycles through custom boot and suspend animations

# Configuration variables
ANIMATION_DIR="/home/deck/custom_animations"
CONFIG_FILE="${ANIMATION_DIR}/config.conf"
BOOT_ANIMATIONS_DIR="${ANIMATION_DIR}/boot"
SUSPEND_ANIMATIONS_DIR="${ANIMATION_DIR}/suspend"

# Random selection state files
BOOT_HISTORY_FILE="${ANIMATION_DIR}/boot_history.txt"
SUSPEND_HISTORY_FILE="${ANIMATION_DIR}/suspend_history.txt"

# Plymouth system animations (for boot process)
DEFAULT_BOOT="/usr/share/plymouth/themes/steamos/steamos.webm"

# Plymouth system suspend animation (for suspend process)
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
STEAM_CSS_SEARCH="{flex-grow:0;width:300px;height:300px}"
STEAM_CSS_REPLACE="{flex-grow:1;width:0100%;height:0100%}"

# Log file location
LOG_FILE="/tmp/animation-daemon.log"

# Create log file if it doesn't exist
touch "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Animation daemon started in RANDOM mode"

# Make sure animation directories exist
for dir in "$ANIMATION_DIR" "$BOOT_ANIMATIONS_DIR" "$SUSPEND_ANIMATIONS_DIR"; do
    if [ ! -d "$dir" ]; then
        log "Creating directory at $dir"
        mkdir -p "$dir"
        chmod 755 "$dir"
    fi
done

# Make sure Steam UI override directory exists
if [ ! -d "$STEAM_ANIMATIONS_DIR" ]; then
    log "Creating Steam UI override directory"
    mkdir -p "$STEAM_ANIMATIONS_DIR"
    # Set proper ownership
    chown -R deck:deck "$STEAM_ANIMATIONS_DIR"
fi

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating default configuration file"
    echo "# Animation Daemon Configuration - RANDOM MODE" > "$CONFIG_FILE"
    echo "RANDOM_MODE=true" >> "$CONFIG_FILE"
    echo "USE_STEAM_UI_METHOD=true" >> "$CONFIG_FILE"
    echo "USE_STEAM_BOOT_METHOD=true" >> "$CONFIG_FILE"
    echo "STEAM_FULLSCREEN_ENABLED=true" >> "$CONFIG_FILE"
    echo "CURRENT_BOOT=" >> "$CONFIG_FILE"
    echo "CURRENT_SUSPEND=" >> "$CONFIG_FILE"
fi

# Source the config file
source "$CONFIG_FILE"

# Function to validate animation file for Steam UI compatibility
validate_animation() {
    local file_path="$1"
    local name=$(basename "$file_path")
    
    # Skip known problematic animations by name
    case "$name" in
        "knuckles_the_screensaver.webm")
            log "Skipping $name - known to cause Steam UI freeze (negative start time)"
            return 1
            ;;
    esac
    
    # Check if ffprobe is available for further validation
    if ! command -v ffprobe >/dev/null 2>&1; then
        return 0  # Skip further validation if ffprobe not available
    fi
    
    # Check for negative start time which can cause Steam UI issues
    local start_time=$(ffprobe "$file_path" -v quiet -show_entries format=start_time -of csv=p=0 2>/dev/null)
    if [[ "$start_time" =~ ^-.*$ ]]; then
        log "Skipping $name - negative start time ($start_time) can cause Steam UI freeze"
        return 1
    fi
    
    return 0
}

# Function to get random animation without repeating recent ones
get_random_animation() {
    local animations_dir="$1"
    local history_file="$2"
    local animation_type="$3"
    
    # Get all available animations (with validation)
    local available_animations=()
    for anim in "$animations_dir"/*.webm; do
        if [ -f "$anim" ]; then
            local name=$(basename "$anim")
            # Validate animation before adding to available list
            if validate_animation "$anim"; then
                available_animations+=("$name")
            fi
        fi
    done
    
    # If no animations available, return empty
    if [ ${#available_animations[@]} -eq 0 ]; then
        log "No $animation_type animations found"
        return 1
    fi
    
    # If only one animation, use it
    if [ ${#available_animations[@]} -eq 1 ]; then
        echo "${available_animations[0]}"
        return 0
    fi
    
    # Create history file if it doesn't exist
    if [ ! -f "$history_file" ]; then
        touch "$history_file"
    fi
    
    # Read recent history (last 50% of total animations, minimum 1)
    local history_size=$((${#available_animations[@]} / 2))
    if [ $history_size -lt 1 ]; then
        history_size=1
    fi
    
    local recent_animations=()
    if [ -f "$history_file" ]; then
        while IFS= read -r line; do
            recent_animations+=("$line")
        done < <(tail -n "$history_size" "$history_file")
    fi
    
    # Find animations not in recent history
    local unused_animations=()
    for anim in "${available_animations[@]}"; do
        local found_in_recent=false
        for recent in "${recent_animations[@]}"; do
            if [ "$anim" = "$recent" ]; then
                found_in_recent=true
                break
            fi
        done
        if [ "$found_in_recent" = false ]; then
            unused_animations+=("$anim")
        fi
    done
    
    # If all animations have been used recently, reset and use all available
    if [ ${#unused_animations[@]} -eq 0 ]; then
        log "All $animation_type animations used recently, resetting cycle"
        unused_animations=("${available_animations[@]}")
        # Clear history file
        > "$history_file"
    fi
    
    # Select random animation from unused ones
    local random_index=$((RANDOM % ${#unused_animations[@]}))
    local selected_animation="${unused_animations[$random_index]}"
    
    # Add to history
    echo "$selected_animation" >> "$history_file"
    
    log "Selected random $animation_type animation: $selected_animation (from $animations_dir)"
    echo "$selected_animation"
    return 0
}

# Function to install random boot animation (Plymouth method)
install_boot_animation() {
    # Check if Plymouth boot video file exists
    if [ ! -f "$DEFAULT_BOOT" ]; then
        log "Plymouth boot video not found at $DEFAULT_BOOT - skipping system boot animation"
        return
    fi
    
    # Backup original if backup doesn't exist
    if [ ! -f "${DEFAULT_BOOT}.original" ]; then
        log "Backing up original system boot animation"
        cp "$DEFAULT_BOOT" "${DEFAULT_BOOT}.original"
    fi
    
    # Get random boot animation
    local selected_boot
    selected_boot=$(get_random_animation "$BOOT_ANIMATIONS_DIR" "$BOOT_HISTORY_FILE" "boot")
    
    if [ $? -eq 0 ] && [ -n "$selected_boot" ]; then
        log "Installing system boot animation: $selected_boot"
        cp "$BOOT_ANIMATIONS_DIR/$selected_boot" "$DEFAULT_BOOT"
        # Update config file
        sed -i "s/^CURRENT_BOOT=.*/CURRENT_BOOT=$selected_boot/" "$CONFIG_FILE"
    else
        log "No boot animations available, using default"
        if [ -f "${DEFAULT_BOOT}.original" ]; then
            cp "${DEFAULT_BOOT}.original" "$DEFAULT_BOOT"
        fi
    fi
}

# Function to install random Steam UI boot animation
install_steam_ui_boot() {
    # Check if we want to use the Steam UI boot method
    if [[ "$USE_STEAM_BOOT_METHOD" != "true" ]]; then
        return
    fi
    
    # Create backup of original if it exists and we haven't backed it up
    if [ -f "$STEAM_BOOT_FILE" ] && [ ! -f "${STEAM_BOOT_FILE}.original" ]; then
        log "Backing up original Steam UI boot animation"
        cp "$STEAM_BOOT_FILE" "${STEAM_BOOT_FILE}.original"
    fi
    
    # Re-source config to get updated CURRENT_BOOT
    source "$CONFIG_FILE"
    
    # If no CURRENT_BOOT is set (Plymouth method skipped), select one now
    if [[ -z "$CURRENT_BOOT" ]]; then
        local selected_boot
        selected_boot=$(get_random_animation "$BOOT_ANIMATIONS_DIR" "$BOOT_HISTORY_FILE" "boot")
        if [ $? -eq 0 ] && [ -n "$selected_boot" ]; then
            sed -i "s/^CURRENT_BOOT=.*/CURRENT_BOOT=$selected_boot/" "$CONFIG_FILE"
            CURRENT_BOOT="$selected_boot"
            log "Selected random boot animation for Steam UI: $selected_boot"
        fi
    fi
    
    # Use the selected boot animation
    if [[ -n "$CURRENT_BOOT" && -f "$BOOT_ANIMATIONS_DIR/$CURRENT_BOOT" ]]; then
        log "Installing Steam UI boot animation: $CURRENT_BOOT"
        cp "$BOOT_ANIMATIONS_DIR/$CURRENT_BOOT" "$STEAM_BOOT_FILE"
        # Set proper ownership
        chown deck:deck "$STEAM_BOOT_FILE"
    else
        log "No Steam UI boot animation to install (CURRENT_BOOT: '$CURRENT_BOOT')"
        # Restore original if it exists
        if [ -f "${STEAM_BOOT_FILE}.original" ]; then
            cp "${STEAM_BOOT_FILE}.original" "$STEAM_BOOT_FILE"
            chown deck:deck "$STEAM_BOOT_FILE"
        elif [ -f "$STEAM_BOOT_FILE" ]; then
            rm "$STEAM_BOOT_FILE"
        fi
    fi
}

# Function to install random suspend animation (Plymouth method)
install_suspend_animation() {
    # Check if Plymouth suspend video file exists
    if [ ! -f "$DEFAULT_SUSPEND" ]; then
        log "Plymouth suspend video not found at $DEFAULT_SUSPEND - skipping system suspend animation"
        return
    fi
    
    # Backup original if backup doesn't exist
    if [ ! -f "${DEFAULT_SUSPEND}.original" ]; then
        log "Backing up original suspend animation"
        cp "$DEFAULT_SUSPEND" "${DEFAULT_SUSPEND}.original"
    fi
    
    # Get random suspend animation
    local selected_suspend
    selected_suspend=$(get_random_animation "$SUSPEND_ANIMATIONS_DIR" "$SUSPEND_HISTORY_FILE" "suspend")
    
    if [ $? -eq 0 ] && [ -n "$selected_suspend" ]; then
        log "Installing Plymouth suspend animation: $selected_suspend"
        cp "$SUSPEND_ANIMATIONS_DIR/$selected_suspend" "$DEFAULT_SUSPEND"
        # Update config file
        sed -i "s/^CURRENT_SUSPEND=.*/CURRENT_SUSPEND=$selected_suspend/" "$CONFIG_FILE"
    else
        log "No suspend animations available, using default"
        if [ -f "${DEFAULT_SUSPEND}.original" ]; then
            cp "${DEFAULT_SUSPEND}.original" "$DEFAULT_SUSPEND"
        fi
    fi
}

# Function to install random Steam UI suspend animation
install_steam_ui_suspend() {
    # Check if we want to use the Steam UI method
    if [[ "$USE_STEAM_UI_METHOD" != "true" ]]; then
        return
    fi
    
    # Create backup of original if it exists and we haven't backed it up
    for file in "$STEAM_SUSPEND_FILE" "$STEAM_SUSPEND_FROM_THROBBER"; do
        if [ -f "$file" ] && [ ! -f "${file}.original" ]; then
            log "Backing up original Steam UI suspend animation: $file"
            cp "$file" "${file}.original"
        fi
    done
    
    # Re-source config to get updated CURRENT_SUSPEND
    source "$CONFIG_FILE"
    
    # If no CURRENT_SUSPEND is set (Plymouth method skipped), select one now
    if [[ -z "$CURRENT_SUSPEND" ]]; then
        local selected_suspend
        selected_suspend=$(get_random_animation "$SUSPEND_ANIMATIONS_DIR" "$SUSPEND_HISTORY_FILE" "suspend")
        if [ $? -eq 0 ] && [ -n "$selected_suspend" ]; then
            sed -i "s/^CURRENT_SUSPEND=.*/CURRENT_SUSPEND=$selected_suspend/" "$CONFIG_FILE"
            CURRENT_SUSPEND="$selected_suspend"
            log "Selected random suspend animation for Steam UI: $selected_suspend"
        fi
    fi
    
    # Use the selected suspend animation
    if [[ -n "$CURRENT_SUSPEND" && -f "$SUSPEND_ANIMATIONS_DIR/$CURRENT_SUSPEND" ]]; then
        log "Installing Steam UI suspend animations: $CURRENT_SUSPEND"
        # Copy to both suspend animation files used by Steam
        cp "$SUSPEND_ANIMATIONS_DIR/$CURRENT_SUSPEND" "$STEAM_SUSPEND_FILE"
        cp "$SUSPEND_ANIMATIONS_DIR/$CURRENT_SUSPEND" "$STEAM_SUSPEND_FROM_THROBBER"
        # Set proper ownership
        chown deck:deck "$STEAM_SUSPEND_FILE" "$STEAM_SUSPEND_FROM_THROBBER"
    else
        log "No Steam UI suspend animations to install (CURRENT_SUSPEND: '$CURRENT_SUSPEND')"
        # Restore originals if they exist
        for file in "$STEAM_SUSPEND_FILE" "$STEAM_SUSPEND_FROM_THROBBER"; do
            if [ -f "${file}.original" ]; then
                cp "${file}.original" "$file"
                chown deck:deck "$file"
            elif [ -f "$file" ]; then
                rm "$file"
            fi
        done
    fi
}

# Function to enable fullscreen for Steam UI suspend animations
enable_steam_fullscreen() {
    # Check if we want to enable fullscreen for Steam UI
    if [[ "$STEAM_FULLSCREEN_ENABLED" != "true" || "$USE_STEAM_UI_METHOD" != "true" ]]; then
        return
    fi
    
    # Check if CSS file exists
    if [ -f "$STEAM_CSS_FILE" ]; then
        # Create backup if it doesn't exist
        if [ ! -f "${STEAM_CSS_FILE}.original" ]; then
            log "Backing up original Steam CSS file"
            cp "$STEAM_CSS_FILE" "${STEAM_CSS_FILE}.original"
        fi
        
        # Check if the CSS needs to be modified
        if grep -q "$STEAM_CSS_SEARCH" "$STEAM_CSS_FILE"; then
            log "Modifying Steam CSS for fullscreen suspend animations"
            sed -i "s/$STEAM_CSS_SEARCH/$STEAM_CSS_REPLACE/g" "$STEAM_CSS_FILE"
            # Set proper ownership
            chown deck:deck "$STEAM_CSS_FILE"
        fi
    else
        log "Steam CSS file not found: $STEAM_CSS_FILE"
    fi
}

# Function to change animations on boot/wake/suspend events
change_animations_on_event() {
    local event_type="$1"
    log "Animation change triggered by: $event_type"
    
    # Select different animations based on event type
    case "$event_type" in
        "boot"|"wake")
            log "System boot/wake detected - selecting new boot animation for next boot"
            install_boot_animation
            install_steam_ui_boot
            ;;
        "suspend")
            log "System suspend detected - selecting new suspend animation for next suspend"
            install_suspend_animation
            install_steam_ui_suspend
            ;;
    esac
}

# Initial installation - select first random animations
log "Selecting initial random animations"
install_boot_animation
install_steam_ui_boot
install_suspend_animation
install_steam_ui_suspend
enable_steam_fullscreen

# Monitor for system events and change animations
log "Starting event monitor for animation changes"
last_boot_time=$(stat -c %Y /proc/uptime 2>/dev/null || echo "0")
css_check_counter=0

while true; do
    # Check every 30 seconds for system state changes
    sleep 30
    
    # Check if system has been rebooted (uptime reset)
    current_boot_time=$(stat -c %Y /proc/uptime 2>/dev/null || echo "0")
    if [ "$current_boot_time" -gt "$last_boot_time" ]; then
        log "System boot detected"
        change_animations_on_event "boot"
        last_boot_time="$current_boot_time"
    fi
    
    # Monitor for suspend/wake by checking for recent suspend events in journal
    if command -v journalctl >/dev/null 2>&1; then
        # Check for recent suspend events (within last 35 seconds)
        suspend_events=$(journalctl --since "35 seconds ago" --grep "suspend" --no-pager -q 2>/dev/null | wc -l)
        resume_events=$(journalctl --since "35 seconds ago" --grep "resume" --no-pager -q 2>/dev/null | wc -l)
        
        # Only process one event type per cycle to avoid conflicts
        if [ "$suspend_events" -gt 0 ] && [ "$resume_events" -eq 0 ]; then
            log "Suspend event detected - selecting new animations for next suspend"
            change_animations_on_event "suspend"
        elif [ "$resume_events" -gt 0 ] && [ "$suspend_events" -eq 0 ]; then
            log "Wake/resume event detected - selecting new animations for next boot"
            change_animations_on_event "wake"
        elif [ "$suspend_events" -gt 0 ] && [ "$resume_events" -gt 0 ]; then
            log "Both suspend and resume events detected - processing as wake event"
            change_animations_on_event "wake"
        fi
    fi
    
    # Check CSS file less frequently (only every 5 minutes instead of 30 seconds)
    css_check_counter=$((css_check_counter + 1))
    if [ $((css_check_counter % 10)) -eq 0 ]; then  # Check every 10 cycles = 5 minutes
        if [ -f "$STEAM_CSS_FILE" ] && [ -f "${STEAM_CSS_FILE}.original" ]; then
            if [[ "$STEAM_FULLSCREEN_ENABLED" == "true" && "$USE_STEAM_UI_METHOD" == "true" ]]; then
                if ! grep -q "$STEAM_CSS_REPLACE" "$STEAM_CSS_FILE"; then
                    log "Steam CSS file changed, reapplying fullscreen modification"
                    enable_steam_fullscreen
                fi
            fi
        fi
    fi
done