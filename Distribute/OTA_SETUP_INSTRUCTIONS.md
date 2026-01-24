# OTA Distribution Setup Instructions

This guide will walk you through setting up Over-The-Air (OTA) distribution for your iOS app using GitHub Pages.

## Table of Contents

1. [Finding Bundle ID and Version in Xcode](#finding-bundle-id-and-version-in-xcode)
2. [Creating an Ad-Hoc Build](#creating-an-ad-hoc-build)
3. [Configuring for Different Developer Accounts](#configuring-for-different-developer-accounts)
4. [Preparing Assets](#preparing-assets)
5. [Deploying to GitHub Pages](#deploying-to-github-pages)
6. [Testing the Installation](#testing-the-installation)
7. [Troubleshooting](#troubleshooting)

---

## Finding Bundle ID and Version in Xcode

### Method 1: Using Xcode UI

1. **Open your project in Xcode**
   - Open `CoachApp.xcodeproj`

2. **Select the project in the navigator**
   - Click on the blue project icon at the top of the file navigator

3. **Select your app target**
   - In the main editor, select the "CoachApp" target under "TARGETS"

4. **Go to the "General" tab**
   - You'll see:
     - **Display Name**: Your app's display name
     - **Bundle Identifier**: Your bundle ID (e.g., `zaid.CoachApp`)
     - **Version**: Marketing version (e.g., `1.0`)
     - **Build**: Current project version (e.g., `1`)

### Method 2: Using Build Settings

1. **Select your target** (same as above)

2. **Go to the "Build Settings" tab**

3. **Search for the following keys:**
   - `PRODUCT_BUNDLE_IDENTIFIER` - Your bundle ID
   - `MARKETING_VERSION` - Your app version
   - `CURRENT_PROJECT_VERSION` - Your build number

### Method 3: Using Terminal

```bash
# Extract Bundle ID
grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER = " CoachApp.xcodeproj/project.pbxproj

# Extract Version
grep -m 1 "MARKETING_VERSION = " CoachApp.xcodeproj/project.pbxproj

# Extract Build Number
grep -m 1 "CURRENT_PROJECT_VERSION = " CoachApp.xcodeproj/project.pbxproj
```

---

## Creating an Ad-Hoc Build

### Prerequisites

- ✅ Apple Developer account (free or paid)
- ✅ Device UDIDs registered in your developer account
- ✅ Ad-Hoc provisioning profile created
- ✅ Distribution certificate installed

### Step-by-Step Guide

#### 1. Register Device UDIDs

**On your iOS device:**
- Go to **Settings** → **General** → **About**
- Find **Identifier** (this is your UDID)
- Copy the UDID

**In Apple Developer Portal:**
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Devices** → **Register a New Device**
4. Add the device UDID
5. Save

#### 2. Create Ad-Hoc Provisioning Profile

1. In Apple Developer Portal, go to **Profiles**
2. Click **+** to create a new profile
3. Select **Ad Hoc** under **Distribution**
4. Select your App ID
5. Select your **Distribution Certificate**
6. Select all devices you want to include
7. Name the profile (e.g., "CoachApp Ad-Hoc")
8. Download the profile

#### 3. Install Provisioning Profile

**Option A: Automatic (Recommended)**
- Xcode will automatically download and install profiles when you sign in with your Apple ID

**Option B: Manual**
- Double-click the downloaded `.mobileprovision` file
- It will be installed in Xcode automatically

#### 4. Configure Signing in Xcode

1. **Open your project in Xcode**

2. **Select the project** in the navigator

3. **Select your target** → **Signing & Capabilities** tab

4. **Configure signing:**
   - ✅ Check "Automatically manage signing" (or uncheck for manual)
   - Select your **Team** from the dropdown
   - Xcode should automatically select your Ad-Hoc profile

5. **Verify the Bundle Identifier** matches what you want

#### 5. Archive the App

1. **Select a generic iOS device** or any connected device
   - In Xcode's toolbar: **Product** → **Destination** → Select "Any iOS Device" or a physical device
   - ⚠️ **Do NOT select a simulator** - simulators cannot create distribution builds

2. **Create Archive:**
   - **Product** → **Archive**
   - Wait for the archive to complete (this may take a few minutes)

3. **Organizer window opens automatically**
   - If not, go to **Window** → **Organizer**

#### 6. Export for Ad-Hoc Distribution

1. **In the Organizer window:**
   - Select your archive
   - Click **Distribute App**

2. **Select Distribution Method:**
   - Choose **Ad Hoc**
   - Click **Next**

3. **Select Distribution Options:**
   - Choose **Rebuild from Bitcode** (if available) or **Upload your app's symbols**
   - Click **Next**

4. **Select Provisioning Profile:**
   - Xcode should automatically select your Ad-Hoc profile
   - Verify it includes your target devices
   - Click **Next**

5. **Review and Export:**
   - Review the summary
   - Click **Export**
   - Choose a location to save the IPA
   - The IPA file will be saved in a folder with the app name

#### 7. Verify the IPA

```bash
# Extract and verify IPA
unzip -q CoachApp.ipa -d /tmp/ipa_check

# Verify bundle ID
plutil -p /tmp/ipa_check/Payload/CoachApp.app/Info.plist | grep CFBundleIdentifier

# Verify signing (should show "Apple Distribution")
codesign -dvv /tmp/ipa_check/Payload/CoachApp.app 2>&1 | grep Authority

# Check provisioning profile
security cms -D -i /tmp/ipa_check/Payload/CoachApp.app/embedded.mobileprovision | grep ProvisionedDevices
```

---

## Configuring for Different Developer Accounts

If you need to configure the app for a different developer account, use the provided configuration script:

### Using the Configuration Script

1. **Run the script:**
   ```bash
   ./configure_ota.sh
   ```

2. **Follow the prompts:**
   - Enter your GitHub Pages URL
   - Enter new Bundle ID (or press Enter to keep current)
   - Enter new Version (or press Enter to keep current)
   - Enter new Build Number (or press Enter to keep current)
   - Enter new Team ID (or press Enter to keep current)
   - Enter new App Name (or press Enter to keep current)

3. **Review the summary** and confirm

4. **The script will:**
   - Update `project.pbxproj` with new values
   - Update `Distribute/manifest.plist` with new values
   - Update `Distribute/index.html` with new values
   - Create backups in `.ota_backup_*` folder
   - Validate the manifest file

5. **After running the script:**
   - Open Xcode
   - Update Signing & Capabilities with the new Team ID
   - Create a new Ad-Hoc build with the new configuration

---

## Preparing Assets

### Required Files

1. **IPA File**
   - The exported Ad-Hoc IPA file
   - Rename it to `app.ipa` (or update manifest.plist to match your filename)

2. **App Icons**
   - **Display Image**: 57x57 pixels PNG (`image57.png`)
   - **Full Size Image**: 512x512 pixels PNG (`image512.png`)

### Creating Icons

**From Xcode:**
1. Open your project
2. Go to **Assets.xcassets** → **AppIcon**
3. Export the required sizes:
   - Export 57x57 for display image
   - Export 512x512 for full size image

**Using Image Tools:**
```bash
# Using sips (macOS built-in)
sips -z 57 57 AppIcon.png --out image57.png
sips -z 512 512 AppIcon.png --out image512.png
```

---

## Deploying to GitHub Pages

### Option 1: Using GitHub Repository

1. **Create a GitHub repository** (or use existing)

2. **Upload files to repository:**
   ```bash
   # Create a branch for GitHub Pages (usually 'gh-pages' or use 'main' with Pages settings)
   git checkout -b gh-pages
   
   # Copy files to repository
   cp app.ipa .
   cp image57.png .
   cp image512.png .
   cp Distribute/manifest.plist .
   cp Distribute/index.html .
   
   # Commit and push
   git add .
   git commit -m "Add OTA distribution files"
   git push origin gh-pages
   ```

3. **Enable GitHub Pages:**
   - Go to repository **Settings** → **Pages**
   - Select source branch (e.g., `gh-pages`)
   - Select folder (usually `/root`)
   - Click **Save**

4. **Your URL will be:**
   - `https://[username].github.io/[repository-name]/`

### Option 2: Using GitHub Releases

1. **Create a release:**
   - Go to repository → **Releases** → **Create a new release**
   - Tag version (e.g., `v1.0`)
   - Upload `app.ipa`, `image57.png`, `image512.png`

2. **Update manifest.plist:**
   - Use the release asset URLs:
     - `https://github.com/[username]/[repo]/releases/download/[tag]/app.ipa`
     - Similar for images

3. **Deploy manifest and index.html:**
   - Use GitHub Pages for these files (as in Option 1)

### Important Notes

- ✅ All files must be served over **HTTPS** (GitHub Pages provides this automatically)
- ✅ Ensure correct MIME types (GitHub Pages handles this automatically)
- ✅ Test that all URLs are accessible before sharing

---

## Testing the Installation

### On Your iOS Device

1. **Open Safari** (not Chrome or Firefox - `itms-services://` links only work in Safari)

2. **Navigate to your GitHub Pages URL:**
   - `https://[username].github.io/[repository-name]/`

3. **Tap "Install App" button**

4. **iOS will prompt:**
   - "This website is trying to download a configuration profile. Do you want to allow this?"
   - Tap **Allow**

5. **Installation prompt:**
   - "Install [App Name]?"
   - Tap **Install**

6. **Wait for download:**
   - The app icon will appear on your home screen
   - A progress indicator will show during download

7. **Trust the Developer:**
   - Go to **Settings** → **General** → **VPN & Device Management** (or **Device Management**)
   - Tap on your developer account
   - Tap **Trust [Developer Name]**
   - Confirm by tapping **Trust**

8. **Launch the app:**
   - Return to home screen
   - Tap the app icon
   - The app should launch successfully

### Troubleshooting Installation

**"Unable to Download App"**
- Device UDID not registered in provisioning profile
- Solution: Add device UDID and create new Ad-Hoc build

**"Cannot Connect to [server]"**
- HTTP instead of HTTPS, or invalid certificate
- Solution: Ensure GitHub Pages URL uses HTTPS

**"Invalid Manifest"**
- XML syntax error or wrong MIME type
- Solution: Validate with `plutil -lint manifest.plist`

**"Untrusted Enterprise Developer"**
- Wrong certificate type
- Solution: Use Ad-Hoc distribution, not Enterprise

**Link doesn't work**
- Opened in wrong browser
- Solution: Must use Safari on iOS device

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Device not in profile | UDID not registered | Add device, regenerate profile, re-export |
| HTTP error | Not using HTTPS | Use GitHub Pages HTTPS URL |
| Invalid manifest | XML error | Run `plutil -lint manifest.plist` |
| Bundle ID mismatch | Values don't match | Verify bundle ID in IPA and manifest |
| Version mismatch | Values don't match | Verify version in IPA and manifest |
| Certificate expired | Old certificate | Renew certificate, create new profile |
| Wrong browser | Not Safari | Must use Safari on iOS |

### Validation Commands

```bash
# Validate manifest
plutil -lint Distribute/manifest.plist

# Check IPA bundle ID
unzip -q app.ipa -d /tmp/check
plutil -p /tmp/check/Payload/CoachApp.app/Info.plist | grep CFBundleIdentifier

# Verify signing
codesign -dvv /tmp/check/Payload/CoachApp.app

# Test URLs
curl -I https://[your-url]/manifest.plist
curl -I https://[your-url]/app.ipa
```

---

## Quick Reference

### Install Link Format
```
itms-services://?action=download-manifest&url=https://[your-url]/manifest.plist
```

### Required Files Structure
```
repository/
├── app.ipa
├── image57.png
├── image512.png
├── manifest.plist
└── index.html
```

### Manifest Requirements
- ✅ Valid XML format
- ✅ HTTPS URLs only
- ✅ Bundle ID matches IPA exactly
- ✅ Version matches IPA exactly
- ✅ Correct image URLs

---

## Next Steps After Setup

1. ✅ Test installation on a registered device
2. ✅ Share the GitHub Pages URL with testers
3. ✅ Collect device UDIDs from testers
4. ✅ Add UDIDs to provisioning profile
5. ✅ Create new Ad-Hoc build with updated profile
6. ✅ Update IPA on GitHub Pages
7. ✅ Notify testers to reinstall

---

**Last Updated**: Generated for CoachApp OTA Distribution  
**For questions or issues, refer to the main project documentation**

