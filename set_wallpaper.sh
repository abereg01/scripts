#!/bin/bash

# Set error handling
set -euo pipefail

# Wallpaper directory
WALLPAPER_DIR="$HOME/.local/share/dwm"
WALLPAPER_FILE="$WALLPAPER_DIR/wallpaper"

# Function to show usage
usage() {
    echo "Usage: $0 <path_to_image>"
    echo "This script copies an image to $WALLPAPER_FILE, replacing any existing wallpaper."
    exit 1
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    usage
fi

# Get the image path from the argument
IMAGE_PATH="$1"

# Check if the image file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image file does not exist."
    exit 1
fi

# Create the wallpaper directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Copy the image to the wallpaper location, overwriting if it exists
cp "$IMAGE_PATH" "$WALLPAPER_FILE"

echo "Wallpaper updated successfully!"
