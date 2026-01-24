# Ad-Hoc OTA Installation Setup Guide

## Project Information
- **App Name**: Fit Fast
- **Bundle ID**: zaid.CoachApp
- **Version**: 1.0
- **Build**: 1
- **Team ID**: K68WL5DJCM

---

## TASK 1: IPA VALIDATION

### Step 1: Export IPA with Ad-Hoc Distribution

1. **Open Xcode**
   - Open `CoachApp.xcodeproj`

2. **Select Generic iOS Device or Any Connected Device**
   - Product → Destination → Select a physical device or "Any iOS Device"

3. **Archive the App**
   - Product → Archive
   - Wait for archive to complete

4. **Export for Ad-Hoc Distribution**
   - In Organizer window, click "Distribute App"
   - Select "Ad Hoc"
   - Click "Next"
   - Select your **Ad-Hoc provisioning profile** (must include target device UDIDs)
   - Click "Next"
   - Choose export location
   - Click "Export"

5. **Verify IPA Contents**
   ```bash
   # Extract and verify IPA
   unzip -q YourApp.ipa -d /tmp/ipa_check
   codesign -dvv /tmp/ipa_check/Payload/CoachApp.app
   
   # Verify bundle ID
   plutil -p /tmp/ipa_check/Payload/CoachApp.app/Info.plist | grep CFBundleIdentifier
   # Must show: "CFBundleIdentifier" => "zaid.CoachApp"
   ```

6. **Verify Signing**
   ```bash
   # Check certificate type (must be "Apple Distribution")
   codesign -dvv /tmp/ipa_check/Payload/CoachApp.app 2>&1 | grep Authority
   
   # Check provisioning profile
   security cms -D -i /tmp/ipa_check/Payload/CoachApp.app/embedded.mobileprovision
   # Verify: ProvisionedDevices array contains target device UDIDs
   # Verify: ProvisionedDevices array contains target device UDIDs
   # Verify: ProvisionedDevices array contains target device UDIDs
   ```

7. **Test Installation via Apple Configurator**
   - Connect target device via USB
   - Open Apple Configurator 2
   - Add device
   - Drag IPA to device
   - Verify installation succeeds

---

## TASK 2: GENERATE MANIFEST.PLIST

### Current Manifest Location
`/Users/zaidaqrawi/Documents/CoachApp/manifest.plist`

### Required Edits

1. **Replace IPA URL**
   - Open `manifest.plist`
   - Find: `REPLACE_WITH_HTTPS_IPA_URL`
   - Replace with your HTTPS URL (e.g., `https://yourdomain.com/CoachApp.ipa`)

2. **Verify All Values**
   - Bundle ID: `zaid.CoachApp` ✓
   - Version: `1.0` ✓
   - Title: `Fit Fast` ✓

3. **Validate XML**
   ```bash
   # Check for BOM, smart quotes, invalid keys
   plutil -lint manifest.plist
   # Must return: manifest.plist: OK
   ```

4. **Verify Encoding**
   ```bash
   # Ensure UTF-8, no BOM
   file manifest.plist
   # Should show: XML document text, UTF-8 Unicode text
   ```

---

## TASK 3: INSTALL LINK GENERATION

### Final Install Link Format
```
itms-services://?action=download-manifest&url=REPLACE_WITH_HTTPS_MANIFEST_URL
```

### Example
```
itms-services://?action=download-manifest&url=https://yourdomain.com/manifest.plist
```

### Usage
1. Host `manifest.plist` on HTTPS server
2. Share the `itms-services://` link
3. User opens link in **Safari** (not Chrome/Firefox)
4. iOS prompts "Install [App Name]"
5. User taps "Install"
6. App installs to home screen

---

## TASK 4: HOSTING VERIFICATION

### Server Requirements

1. **HTTPS Certificate**
   - Valid TLS certificate (not self-signed)
   - Certificate chain complete
   - No expired certificates

2. **MIME Types**
   - `.plist` → `application/xml` or `text/xml`
   - `.ipa` → `application/octet-stream` or `application/iphone`

3. **HTTP Headers**
   ```
   Content-Type: application/xml (for .plist)
   Content-Type: application/octet-stream (for .ipa)
   Accept-Ranges: bytes
   ```

4. **Server Configuration Examples**

   **Apache (.htaccess)**
   ```apache
   AddType application/xml .plist
   AddType application/octet-stream .ipa
   ```

   **Nginx**
   ```nginx
   location ~ \.plist$ {
       add_header Content-Type application/xml;
   }
   location ~ \.ipa$ {
       add_header Content-Type application/octet-stream;
       add_header Accept-Ranges bytes;
   }
   ```

5. **Test URLs**
   ```bash
   # Test manifest accessibility
   curl -I https://yourdomain.com/manifest.plist
   # Must return: Content-Type: application/xml
   
   # Test IPA accessibility
   curl -I https://yourdomain.com/CoachApp.ipa
   # Must return: Content-Type: application/octet-stream
   ```

---

## TASK 5: FAILURE PREVENTION CHECKLIST

### Pre-Deployment Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Device UDID registered in Apple Developer Portal | ⬜ | Get UDID: Settings → General → About → Identifier |
| Ad-Hoc provisioning profile includes device UDID | ⬜ | Verify in Xcode → Signing & Capabilities |
| Provisioning profile matches IPA | ⬜ | Check embedded.mobileprovision |
| Bundle ID matches manifest | ⬜ | Must be exactly `zaid.CoachApp` |
| Version matches IPA | ⬜ | Must be exactly `1.0` |
| Distribution certificate not expired | ⬜ | Check in Keychain Access |
| Provisioning profile not expired | ⬜ | Check expiration date |
| IPA signed with Apple Distribution | ⬜ | Not Development certificate |
| Manifest URL is HTTPS | ⬜ | HTTP will fail |
| IPA URL is HTTPS | ⬜ | HTTP will fail |
| Server serves correct MIME types | ⬜ | Test with curl |
| TLS certificate valid | ⬜ | No self-signed certs |
| Manifest XML valid | ⬜ | Run `plutil -lint` |
| No BOM in manifest | ⬜ | Check file encoding |
| No smart quotes in manifest | ⬜ | Use straight quotes only |

---

## Known Failure Causes and Fixes

### "Unable to Download App"
- **Cause**: Device UDID not in provisioning profile
- **Fix**: Add device UDID to Ad-Hoc profile, regenerate, re-export IPA

### "Cannot Connect to [server]"
- **Cause**: HTTP instead of HTTPS, or invalid certificate
- **Fix**: Use HTTPS with valid TLS certificate

### "Invalid Manifest"
- **Cause**: XML syntax error, BOM, smart quotes, wrong MIME type
- **Fix**: Validate with `plutil -lint`, ensure UTF-8 no BOM, set correct MIME type

### "App Installation Failed"
- **Cause**: Bundle ID mismatch, version mismatch, expired certificate
- **Fix**: Verify bundle ID and version match exactly, renew certificates

### "Untrusted Enterprise Developer"
- **Cause**: Using Enterprise certificate (wrong)
- **Fix**: Use Ad-Hoc distribution with Apple Distribution certificate

### "This app cannot be installed because its integrity could not be verified"
- **Cause**: IPA not properly signed, or signature broken
- **Fix**: Re-export IPA with correct Ad-Hoc profile

### Link Opens in Wrong Browser
- **Cause**: User opened in Chrome/Firefox
- **Fix**: Must open `itms-services://` link in Safari only

---

## Quick Reference

### Extract Bundle Info from IPA
```bash
unzip -q CoachApp.ipa -d /tmp/extract
plutil -p /tmp/extract/Payload/CoachApp.app/Info.plist | grep -E "(CFBundleIdentifier|CFBundleShortVersionString|CFBundleVersion)"
```

### Verify Provisioning Profile
```bash
security cms -D -i /tmp/extract/Payload/CoachApp.app/embedded.mobileprovision | grep -A 5 ProvisionedDevices
```

### Test Install Link (macOS)
```bash
open "itms-services://?action=download-manifest&url=https://yourdomain.com/manifest.plist"
```

---

## Final Deliverables

1. ✅ **manifest.plist** - Ready (update IPA_URL)
2. ✅ **Install Link** - Generate after hosting manifest
3. ✅ **Verification Checklist** - See above table
4. ✅ **Known Issues & Fixes** - Documented above

---

## Next Steps

1. Export IPA with Ad-Hoc distribution
2. Upload IPA to HTTPS server
3. Update `manifest.plist` with IPA URL
4. Upload `manifest.plist` to HTTPS server
5. Generate install link: `itms-services://?action=download-manifest&url=[MANIFEST_URL]`
6. Test on registered device via Safari
7. Share link with clients

---

**Last Updated**: Generated for CoachApp Ad-Hoc Distribution
**Compliance**: Apple Ad-Hoc Distribution Guidelines Only

