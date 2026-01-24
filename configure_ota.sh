#!/bin/bash

# OTA Configuration Script
# This script configures the app for OTA distribution with a different developer account

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# File paths
PROJECT_FILE="CoachApp.xcodeproj/project.pbxproj"
MANIFEST_FILE="Distribute/manifest.plist"
INDEX_FILE="Distribute/index.html"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to script directory
cd "$SCRIPT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OTA Distribution Configuration Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if required files exist
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Error: $PROJECT_FILE not found${NC}"
    exit 1
fi

if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: $MANIFEST_FILE not found${NC}"
    exit 1
fi

if [ ! -f "$INDEX_FILE" ]; then
    echo -e "${RED}Error: $INDEX_FILE not found${NC}"
    exit 1
fi

# Extract current values from project.pbxproj
echo -e "${YELLOW}Extracting current values from Xcode project...${NC}"

CURRENT_BUNDLE_ID=$(grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER = " "$PROJECT_FILE" | sed 's/.*PRODUCT_BUNDLE_IDENTIFIER = \([^;]*\);.*/\1/' | xargs)
CURRENT_VERSION=$(grep -m 1 "MARKETING_VERSION = " "$PROJECT_FILE" | sed 's/.*MARKETING_VERSION = \([^;]*\);.*/\1/' | xargs)
CURRENT_BUILD=$(grep -m 1 "CURRENT_PROJECT_VERSION = " "$PROJECT_FILE" | sed 's/.*CURRENT_PROJECT_VERSION = \([^;]*\);.*/\1/' | xargs)
CURRENT_TEAM=$(grep -m 1 "DEVELOPMENT_TEAM = " "$PROJECT_FILE" | sed 's/.*DEVELOPMENT_TEAM = \([^;]*\);.*/\1/' | xargs)
CURRENT_APP_NAME=$(grep -m 1 'INFOPLIST_KEY_CFBundleDisplayName = ' "$PROJECT_FILE" | sed 's/.*INFOPLIST_KEY_CFBundleDisplayName = "\([^"]*\)";.*/\1/' | xargs)

echo -e "${GREEN}Current values found:${NC}"
echo "  Bundle ID: $CURRENT_BUNDLE_ID"
echo "  Version: $CURRENT_VERSION"
echo "  Build: $CURRENT_BUILD"
echo "  Team ID: $CURRENT_TEAM"
echo "  App Name: $CURRENT_APP_NAME"
echo ""

# Prompt for new values
echo -e "${YELLOW}Enter new configuration values (press Enter to keep current value):${NC}"
echo ""

read -p "GitHub Pages Base URL (e.g., https://username.github.io/repo-name): " GITHUB_URL
if [ -z "$GITHUB_URL" ]; then
    echo -e "${RED}Error: GitHub URL is required${NC}"
    exit 1
fi

# Remove trailing slash if present
GITHUB_URL="${GITHUB_URL%/}"

read -p "Bundle Identifier [$CURRENT_BUNDLE_ID]: " NEW_BUNDLE_ID
NEW_BUNDLE_ID=${NEW_BUNDLE_ID:-$CURRENT_BUNDLE_ID}

read -p "App Version [$CURRENT_VERSION]: " NEW_VERSION
NEW_VERSION=${NEW_VERSION:-$CURRENT_VERSION}

read -p "Build Number [$CURRENT_BUILD]: " NEW_BUILD
NEW_BUILD=${NEW_BUILD:-$CURRENT_BUILD}

read -p "Team ID [$CURRENT_TEAM]: " NEW_TEAM
NEW_TEAM=${NEW_TEAM:-$CURRENT_TEAM}

read -p "App Name [$CURRENT_APP_NAME]: " NEW_APP_NAME
NEW_APP_NAME=${NEW_APP_NAME:-$CURRENT_APP_NAME}

echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  GitHub URL: $GITHUB_URL"
echo "  Bundle ID: $NEW_BUNDLE_ID"
echo "  Version: $NEW_VERSION"
echo "  Build: $NEW_BUILD"
echo "  Team ID: $NEW_TEAM"
echo "  App Name: $NEW_APP_NAME"
echo ""

read -p "Proceed with these changes? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Updating files...${NC}"

# Backup original files
BACKUP_DIR=".ota_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$PROJECT_FILE" "$BACKUP_DIR/project.pbxproj.bak"
cp "$MANIFEST_FILE" "$BACKUP_DIR/manifest.plist.bak"
cp "$INDEX_FILE" "$BACKUP_DIR/index.html.bak"
echo -e "${GREEN}Backups created in $BACKUP_DIR${NC}"

# Update project.pbxproj
echo "Updating $PROJECT_FILE..."

# Update Bundle Identifier (all occurrences)
sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = $CURRENT_BUNDLE_ID;|PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID;|g" "$PROJECT_FILE"

# Update Version (all occurrences)
sed -i '' "s|MARKETING_VERSION = $CURRENT_VERSION;|MARKETING_VERSION = $NEW_VERSION;|g" "$PROJECT_FILE"

# Update Build (all occurrences)
sed -i '' "s|CURRENT_PROJECT_VERSION = $CURRENT_BUILD;|CURRENT_PROJECT_VERSION = $NEW_BUILD;|g" "$PROJECT_FILE"

# Update Team ID (all occurrences)
if [ -n "$CURRENT_TEAM" ] && [ "$CURRENT_TEAM" != "$NEW_TEAM" ]; then
    sed -i '' "s|DEVELOPMENT_TEAM = $CURRENT_TEAM;|DEVELOPMENT_TEAM = $NEW_TEAM;|g" "$PROJECT_FILE"
fi

# Update App Name (all occurrences)
if [ -n "$CURRENT_APP_NAME" ] && [ "$CURRENT_APP_NAME" != "$NEW_APP_NAME" ]; then
    sed -i '' "s|INFOPLIST_KEY_CFBundleDisplayName = \"$CURRENT_APP_NAME\";|INFOPLIST_KEY_CFBundleDisplayName = \"$NEW_APP_NAME\";|g" "$PROJECT_FILE"
fi

# Update manifest.plist
echo "Updating $MANIFEST_FILE..."

# Escape special characters for sed
ESCAPED_GITHUB_URL=$(echo "$GITHUB_URL" | sed 's/[[\.*^$()+?{|]/\\&/g')
ESCAPED_BUNDLE_ID=$(echo "$NEW_BUNDLE_ID" | sed 's/[[\.*^$()+?{|]/\\&/g')
ESCAPED_VERSION=$(echo "$NEW_VERSION" | sed 's/[[\.*^$()+?{|]/\\&/g')
ESCAPED_APP_NAME=$(echo "$NEW_APP_NAME" | sed 's/[[\.*^$()+?{|]/\\&/g')

sed -i '' "s|https://\[MY_FREE_URL\]|$ESCAPED_GITHUB_URL|g" "$MANIFEST_FILE"
sed -i '' "s|\[INSERT_BUNDLE_ID_FROM_XCODE\]|$ESCAPED_BUNDLE_ID|g" "$MANIFEST_FILE"
sed -i '' "s|\[INSERT_VERSION_FROM_XCODE\]|$ESCAPED_VERSION|g" "$MANIFEST_FILE"
sed -i '' "s|\[INSERT_APP_NAME\]|$ESCAPED_APP_NAME|g" "$MANIFEST_FILE"

# Update index.html
echo "Updating $INDEX_FILE..."

sed -i '' "s|https://\[MY_FREE_URL\]|$ESCAPED_GITHUB_URL|g" "$INDEX_FILE"
sed -i '' "s|\[INSERT_APP_NAME\]|$ESCAPED_APP_NAME|g" "$INDEX_FILE"

# Validate manifest.plist
echo ""
echo -e "${YELLOW}Validating manifest.plist...${NC}"
if plutil -lint "$MANIFEST_FILE" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ manifest.plist is valid${NC}"
else
    echo -e "${RED}✗ manifest.plist validation failed${NC}"
    plutil -lint "$MANIFEST_FILE"
    echo ""
    echo -e "${YELLOW}Restoring from backup...${NC}"
    cp "$BACKUP_DIR/manifest.plist.bak" "$MANIFEST_FILE"
    exit 1
fi

# Verify changes
echo ""
echo -e "${YELLOW}Verifying changes...${NC}"

# Check if bundle ID was updated
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID;" "$PROJECT_FILE"; then
    echo -e "${GREEN}✓ Bundle ID updated in project file${NC}"
else
    echo -e "${RED}✗ Bundle ID update failed${NC}"
fi

# Check if manifest was updated
if grep -q "$NEW_BUNDLE_ID" "$MANIFEST_FILE"; then
    echo -e "${GREEN}✓ Bundle ID updated in manifest${NC}"
else
    echo -e "${RED}✗ Manifest bundle ID update failed${NC}"
fi

if grep -q "$GITHUB_URL" "$MANIFEST_FILE"; then
    echo -e "${GREEN}✓ GitHub URL updated in manifest${NC}"
else
    echo -e "${RED}✗ Manifest URL update failed${NC}"
fi

# Check if index.html was updated
if grep -q "$GITHUB_URL" "$INDEX_FILE"; then
    echo -e "${GREEN}✓ GitHub URL updated in index.html${NC}"
else
    echo -e "${RED}✗ index.html URL update failed${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode"
echo "2. Update your signing & capabilities with the new Team ID"
echo "3. Create an Ad-Hoc build (see Distribute/OTA_SETUP_INSTRUCTIONS.md)"
echo "4. Upload the IPA and images to: $GITHUB_URL"
echo "5. Deploy the Distribute folder to GitHub Pages"
echo ""
echo "Install link will be:"
echo -e "${BLUE}itms-services://?action=download-manifest&url=$GITHUB_URL/manifest.plist${NC}"
echo ""

