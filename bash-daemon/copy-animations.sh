#!/bin/bash

# Script to copy animations from the existing boot directory to the appropriate locations

# Create boot and suspend directories if they don't exist
mkdir -p "boot"
mkdir -p "suspend"

# If we have files in the existing boot directory, copy them to the boot directory
if [ -d "boot" ]; then
    echo "Found boot animations. Copying to boot directory..."
    
    # Count the number of animations
    num_animations=$(find boot -name "*.webm" | wc -l)
    echo "Found $num_animations boot animations"
    
    # If there are any animations, list them
    if [ "$num_animations" -gt 0 ]; then
        echo "Boot animations:"
        ls -la boot/*.webm
    fi
fi

echo "Ready for installation."
echo "Run 'sudo bash install.sh' to install the daemon service."