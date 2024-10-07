#!/bin/bash

# Configuration
GIT_REPO="https://github.com/yourusername/yourproject.git"  # Replace with your repo URL
GIT_BRANCH_OR_TAG=$1  # Accept version as the first argument

# Directories
PROJECT_DIR="/home/nvidia/ota-update-test"
CURRENT_VERSION_DIR="$PROJECT_DIR/current_version"
PREVIOUS_VERSION_DIR="$PROJECT_DIR/previous_version"
NEW_VERSION_DIR="$PROJECT_DIR/new_version"

# Function to rollback to the previous version
rollback() {
    echo "Rolling back to the previous version..."
    rm -rf "$CURRENT_VERSION_DIR"  # Remove current version
    mv "$PREVIOUS_VERSION_DIR" "$CURRENT_VERSION_DIR"  # Restore previous version
    echo "Rollback complete. Running previous version."
    # Optionally restart your service or application here, e.g., systemctl restart your-app
}

# Function to install new version
install_new_version() {
    echo "Running installation for the new version..."
    cd "$NEW_VERSION_DIR" || { echo "Failed to change directory to new version"; rollback; exit 1; }

    # Run the install.sh script from the cloned project
    if ./install.sh; then
        echo "Installation successful. Switching to the new version."
        rm -rf "$PREVIOUS_VERSION_DIR"  # Remove previous version
        mv "$CURRENT_VERSION_DIR" "$PREVIOUS_VERSION_DIR"  # Backup current version
        mv "$NEW_VERSION_DIR" "$CURRENT_VERSION_DIR"  # Move new version to current version
        echo "New version is now live."
        # Optionally restart your service or application here, e.g., systemctl restart your-app
    else
        echo "Installation failed."
        rollback
        exit 1
    fi
}

# Step 1: Clone the project with the specified version (branch, tag, or commit hash)
if [ -z "$GIT_BRANCH_OR_TAG" ]; then
    echo "Error: No version provided. Usage: ./ota_update.sh <version>"
    exit 1
fi

echo "Cloning the project version: $GIT_BRANCH_OR_TAG..."
rm -rf "$NEW_VERSION_DIR"  # Ensure the new_version directory is empty
git clone -b "$GIT_BRANCH_OR_TAG" "$GIT_REPO" "$NEW_VERSION_DIR"

if [ $? -ne 0 ]; then
    echo "Error cloning repository. Rolling back to the previous version."
    rollback
    exit 1
else
    echo "Clone successful. Proceeding with installation."
    install_new_version
fi
