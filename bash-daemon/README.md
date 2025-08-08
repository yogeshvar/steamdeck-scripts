# Steam Deck Custom Animation Daemon

This daemon service automatically manages custom boot and suspend animations on your Steam Deck with intelligent random selection. It supports both system-level (Plymouth) animations and Steam UI animations, and can automatically cycle through your animations without repeating the same one twice in a row.

## Installation

### Automatic Installation (Recommended)

1. Place your custom WebM animation files in a `boot/` folder next to these scripts
2. (Optional) Place suspend animations in a `suspend/` folder, or they'll use boot animations
3. Copy these files to your Steam Deck
4. Enter Desktop Mode on your Steam Deck
5. Open a terminal and navigate to the directory containing these scripts
6. Run: `sudo bash install.sh`

That's it! The daemon will automatically:
- Install all your animations
- Enable random mode with intelligent cycling
- Configure both system and Steam UI methods
- Start running immediately

### Manual Installation (Advanced)
If you prefer to configure everything manually, edit the `install.sh` script to disable automatic mode before running.

## Animation Methods

This daemon supports multiple methods for applying animations:

### Boot Animations

#### 1. System Method (Plymouth)
- Replaces the system animation at `/usr/share/plymouth/themes/steamos/steamos.webm`
- This animation shows during the actual boot process
- Requires root access to modify system files

#### 2. Steam UI Method
- Installs boot animation to `/home/deck/.steam/root/config/uioverrides/movies/deck_startup.webm`
- This animation shows when Steam UI loads after boot or restarts
- Shows in Steam UI when you launch it in Desktop Mode

### Suspend Animations

#### 1. System Method (Plymouth)
- Replaces the system animation at `/usr/share/plymouth/themes/steamos/suspend.webm`
- This animation shows when suspending from Desktop Mode
- Requires root access to modify system files
- No special CSS modifications needed

#### 2. Steam UI Method
- Installs animations to `/home/deck/.steam/root/config/uioverrides/movies/`
- This animation shows when suspending from Gaming Mode
- Can be displayed as fullscreen (with CSS modification) or default size
- When using fullscreen, modifies Steam CSS file to enable fullscreen display

The installer will ask which method(s) you want to use for both boot and suspend animations. For the best experience, we recommend using both methods for each.

## Using Custom Animations

### Random Mode (Default)
By default, the daemon runs in random mode:
- Automatically selects different animations for each boot, wake, and suspend event
- Never shows the same animation twice in a row
- Cycles through all your animations before repeating any
- No user interaction required

### Managing Animations
To manage your animations after installation:
1. Run: `sudo /home/deck/animation-daemon/select-animation.sh`
2. In random mode, you can:
   - Toggle between random and manual mode
   - Reset the random selection history
   - Change animation methods (System/Steam UI)
   - Import new animations
   - Apply changes

3. In manual mode, you can:
   - Select specific boot and suspend animations
   - Configure animation methods individually
   - Return to random mode anytime

### Directory Structure
- Boot animations: `/home/deck/custom_animations/boot/`
- Suspend animations: `/home/deck/custom_animations/suspend/`

## Adding New Animations

You can add new animations in two ways:

1. **Before installation:**
   - Place WebM files in the `boot/` folder before running the installer
   - Place WebM files in the `suspend/` folder before running the installer

2. **After installation:**
   - Use the animation selector: `sudo /home/deck/animation-daemon/select-animation.sh`
   - Select "Import new animations" from the menu
   - Follow the prompts to import new boot or suspend animations

## File Format Requirements

- Format: WebM video
- Boot animation: ~5 seconds duration
- Suspend animation: ~2-3 seconds duration

For Steam UI animations:
- For boot animations (deck_startup.webm): 1280x800 fullscreen animations work best
- For suspend animations:
  - If using default size: 450x450 with transparent background works best
  - If using fullscreen: 1280x800 (Steam Deck native resolution) works best

## Checking Status

Check if the daemon is running:
```
systemctl status animation-daemon.service
```

View logs:
```
cat /tmp/animation-daemon.log
```

Force new animation selection:
```
sudo systemctl restart animation-daemon.service
```

View current configuration:
```
cat /home/deck/custom_animations/config.conf
```

## Configuration Options

The configuration file at `/home/deck/custom_animations/config.conf` contains:

- `RANDOM_MODE`: Set to "true" for automatic random selection (default)
- `CURRENT_BOOT`: Filename of the currently selected boot animation
- `CURRENT_SUSPEND`: Filename of the currently selected suspend animation
- `USE_DEFAULT_BOOT`: Set to "true" to use default boot animation (manual mode only)
- `USE_DEFAULT_SUSPEND`: Set to "true" to use default suspend animation (manual mode only)
- `USE_STEAM_BOOT_METHOD`: Set to "true" to apply boot animations to Steam UI
- `USE_STEAM_UI_METHOD`: Set to "true" to apply suspend animations to Steam UI
- `STEAM_FULLSCREEN_ENABLED`: Set to "true" to enable fullscreen for Steam UI suspend animations

## Random Selection Algorithm

The daemon uses an intelligent random selection system:
1. Maintains separate history files for boot and suspend animations
2. Tracks the last 50% of total animations used
3. Only selects from animations not in recent history
4. When all animations have been used, resets the history and starts over
5. Ensures you see all your animations before any repeats

## Uninstalling

To remove the daemon and restore original animations:
```
sudo bash uninstall.sh
```
The uninstaller will ask if you want to keep your custom animations.

## How It Works

### Random Mode (Default)
The daemon automatically:
1. Monitors system events (boot, suspend, wake)
2. Selects random animations using intelligent algorithm
3. Applies animations to both system and Steam UI
4. Tracks usage history to prevent immediate repeats
5. Cycles through all animations before any repeats

### Technical Details
The daemon:
1. Maintains separate collections of boot and suspend animations
2. Backs up original SteamOS animations before first use
3. Monitors `/proc/uptime` for boot detection
4. Uses `journalctl` to detect suspend/wake events
5. Applies animations to both system (Plymouth) and Steam UI locations
6. Modifies Steam CSS for fullscreen suspend animations
7. Runs as a systemd service with automatic restart
8. Logs all activity to `/tmp/animation-daemon.log`