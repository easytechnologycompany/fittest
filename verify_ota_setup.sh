#!/bin/bash
# Ad-Hoc OTA Installation Verification Script
# Usage: ./verify_ota_setup.sh [IPA_PATH] [MANIFEST_PATH]

set -e

IPA_PATH="${1:-}"
MANIFEST_PATH="${2:-./manifest.plist}"

echo "=========================================="
echo "Ad-Hoc OTA Installation Verification"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Verify manifest.plist exists
echo "1. Checking manifest.plist..."
if [ ! -f "$MANIFEST_PATH" ]; then
    check_fail "manifest.plist not found at $MANIFEST_PATH"
    exit 1
fi
check_pass "manifest.plist exists"

# Validate manifest XML
echo ""
echo "2. Validating manifest.plist XML..."
if plutil -lint "$MANIFEST_PATH" > /dev/null 2>&1; then
    check_pass "manifest.plist is valid XML"
else
    check_fail "manifest.plist has XML errors"
    plutil -lint "$MANIFEST_PATH"
    exit 1
fi

# Check for BOM
echo ""
echo "3. Checking for BOM (Byte Order Mark)..."
if file "$MANIFEST_PATH" | grep -q "UTF-8"; then
    check_pass "File encoding is UTF-8"
else
    check_warn "File encoding may not be UTF-8"
fi

# Extract and verify manifest values
echo ""
echo "4. Verifying manifest.plist values..."
BUNDLE_ID=$(plutil -extract items.0.metadata.bundle-identifier raw "$MANIFEST_PATH" 2>/dev/null || echo "")
VERSION=$(plutil -extract items.0.metadata.bundle-version raw "$MANIFEST_PATH" 2>/dev/null || echo "")
TITLE=$(plutil -extract items.0.metadata.title raw "$MANIFEST_PATH" 2>/dev/null || echo "")
IPA_URL=$(plutil -extract items.0.assets.0.url raw "$MANIFEST_PATH" 2>/dev/null || echo "")

if [ "$BUNDLE_ID" = "zaid.CoachApp" ]; then
    check_pass "Bundle ID: $BUNDLE_ID"
else
    check_fail "Bundle ID mismatch: expected 'zaid.CoachApp', got '$BUNDLE_ID'"
fi

if [ "$VERSION" = "1.0" ]; then
    check_pass "Version: $VERSION"
else
    check_warn "Version: $VERSION (expected 1.0)"
fi

if [ -n "$TITLE" ]; then
    check_pass "Title: $TITLE"
else
    check_fail "Title is missing"
fi

if [[ "$IPA_URL" == https://* ]]; then
    check_pass "IPA URL is HTTPS: $IPA_URL"
elif [[ "$IPA_URL" == REPLACE_WITH_HTTPS_IPA_URL ]]; then
    check_warn "IPA URL not set (still has placeholder)"
else
    check_fail "IPA URL must be HTTPS, got: $IPA_URL"
fi

# Verify IPA if provided
if [ -n "$IPA_PATH" ] && [ -f "$IPA_PATH" ]; then
    echo ""
    echo "5. Verifying IPA file..."
    
    # Extract IPA
    TEMP_DIR=$(mktemp -d)
    unzip -q "$IPA_PATH" -d "$TEMP_DIR" 2>/dev/null || {
        check_fail "Failed to extract IPA"
        rm -rf "$TEMP_DIR"
        exit 1
    }
    check_pass "IPA extracted successfully"
    
    # Find .app bundle
    APP_BUNDLE=$(find "$TEMP_DIR" -name "*.app" -type d | head -1)
    if [ -z "$APP_BUNDLE" ]; then
        check_fail "No .app bundle found in IPA"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Check bundle ID in IPA
    IPA_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$APP_BUNDLE/Info.plist" 2>/dev/null || echo "")
    if [ "$IPA_BUNDLE_ID" = "zaid.CoachApp" ]; then
        check_pass "IPA Bundle ID matches: $IPA_BUNDLE_ID"
    else
        check_fail "IPA Bundle ID mismatch: expected 'zaid.CoachApp', got '$IPA_BUNDLE_ID'"
    fi
    
    # Check version in IPA
    IPA_VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP_BUNDLE/Info.plist" 2>/dev/null || echo "")
    if [ "$IPA_VERSION" = "1.0" ]; then
        check_pass "IPA Version matches: $IPA_VERSION"
    else
        check_warn "IPA Version: $IPA_VERSION (expected 1.0)"
    fi
    
    # Check code signing
    echo ""
    echo "6. Verifying code signature..."
    if codesign -dvv "$APP_BUNDLE" 2>&1 | grep -q "Apple Distribution"; then
        check_pass "Signed with Apple Distribution certificate"
    else
        check_fail "Not signed with Apple Distribution certificate"
        codesign -dvv "$APP_BUNDLE" 2>&1 | grep Authority || true
    fi
    
    # Check provisioning profile
    echo ""
    echo "7. Checking provisioning profile..."
    if [ -f "$APP_BUNDLE/embedded.mobileprovision" ]; then
        PROVISION_TYPE=$(security cms -D -i "$APP_BUNDLE/embedded.mobileprovision" 2>/dev/null | plutil -extract ProvisionedDevices raw - 2>/dev/null || echo "")
        if [ -n "$PROVISION_TYPE" ]; then
            check_pass "Ad-Hoc provisioning profile detected (has ProvisionedDevices)"
        else
            check_fail "Provisioning profile is not Ad-Hoc (no ProvisionedDevices)"
        fi
    else
        check_fail "No embedded.mobileprovision found"
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
else
    echo ""
    echo "5. Skipping IPA verification (no IPA path provided)"
    echo "   Usage: $0 [IPA_PATH] [MANIFEST_PATH]"
fi

echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Update manifest.plist with your HTTPS IPA URL"
echo "2. Upload manifest.plist to HTTPS server"
echo "3. Upload IPA to HTTPS server"
echo "4. Generate install link:"
echo "   itms-services://?action=download-manifest&url=[MANIFEST_URL]"
echo "5. Test on registered device via Safari"

