# Ad-Hoc OTA Installation - Validation Checklist

## Pre-Deployment Validation

| # | Check | Status | Verification Method |
|---|-------|--------|---------------------|
| 1 | Device UDID registered in Apple Developer Portal | ⬜ | Settings → General → About → Identifier |
| 2 | Ad-Hoc provisioning profile includes device UDID | ⬜ | Xcode → Signing & Capabilities → Check profile |
| 3 | Provisioning profile matches IPA | ⬜ | `security cms -D -i embedded.mobileprovision` |
| 4 | Bundle ID matches manifest | ✅ | `zaid.CoachApp` (verified) |
| 5 | Version matches IPA | ✅ | `1.0` (verified) |
| 6 | Distribution certificate not expired | ⬜ | Keychain Access → Certificates |
| 7 | Provisioning profile not expired | ⬜ | Apple Developer Portal → Profiles |
| 8 | IPA signed with Apple Distribution | ⬜ | `codesign -dvv` (check Authority) |
| 9 | Manifest URL is HTTPS | ⬜ | Update `REPLACE_WITH_HTTPS_IPA_URL` |
| 10 | IPA URL is HTTPS | ⬜ | Must be HTTPS (not HTTP) |
| 11 | Server serves correct MIME types | ⬜ | `.plist` → `application/xml`, `.ipa` → `application/octet-stream` |
| 12 | TLS certificate valid | ⬜ | No self-signed certificates |
| 13 | Manifest XML valid | ✅ | `plutil -lint` passed |
| 14 | No BOM in manifest | ✅ | UTF-8 encoding verified |
| 15 | No smart quotes in manifest | ✅ | XML structure verified |

---

## IPA Validation Checklist

| # | Check | Status | Command |
|---|-------|--------|---------|
| 1 | IPA extracts successfully | ⬜ | `unzip -q IPA.ipa -d /tmp` |
| 2 | Bundle ID in IPA matches `zaid.CoachApp` | ⬜ | `plutil -p Info.plist \| grep CFBundleIdentifier` |
| 3 | Version in IPA matches `1.0` | ⬜ | `plutil -p Info.plist \| grep CFBundleShortVersionString` |
| 4 | Signed with Apple Distribution | ⬜ | `codesign -dvv` (check for "Apple Distribution") |
| 5 | Ad-Hoc provisioning profile embedded | ⬜ | `security cms -D -i embedded.mobileprovision` |
| 6 | ProvisionedDevices array exists | ⬜ | Check for `ProvisionedDevices` key |
| 7 | Target device UDID in ProvisionedDevices | ⬜ | Verify UDID in array |
| 8 | IPA installs via Apple Configurator | ⬜ | Test on registered device |

---

## Server Configuration Checklist

| # | Check | Status | Verification |
|---|-------|--------|--------------|
| 1 | HTTPS enabled | ⬜ | URL starts with `https://` |
| 2 | Valid TLS certificate | ⬜ | No certificate errors in browser |
| 3 | Certificate chain complete | ⬜ | All intermediate certs present |
| 4 | `.plist` MIME type: `application/xml` | ⬜ | `curl -I manifest.plist` |
| 5 | `.ipa` MIME type: `application/octet-stream` | ⬜ | `curl -I CoachApp.ipa` |
| 6 | Byte-range requests supported | ⬜ | `Accept-Ranges: bytes` header |
| 7 | Files accessible via HTTPS | ⬜ | Test URLs in browser |

---

## Install Link Validation

| # | Check | Status | Format |
|---|-------|--------|--------|
| 1 | Link uses `itms-services://` protocol | ⬜ | `itms-services://?action=download-manifest&url=...` |
| 2 | Manifest URL is HTTPS | ⬜ | URL parameter must be HTTPS |
| 3 | Link opens in Safari | ⬜ | Test on iOS device |
| 4 | iOS prompts "Install" | ⬜ | Verify prompt appears |
| 5 | App installs without error | ⬜ | Complete installation test |

---

## Known Failure Causes and Fixes

### ❌ "Unable to Download App"
**Cause**: Device UDID not registered in Ad-Hoc provisioning profile  
**Fix**: 
1. Get device UDID: Settings → General → About → Identifier
2. Add UDID to profile in Apple Developer Portal
3. Download updated profile
4. Re-export IPA with new profile

### ❌ "Cannot Connect to [server]"
**Cause**: HTTP instead of HTTPS, or invalid/self-signed certificate  
**Fix**: 
1. Use HTTPS only (not HTTP)
2. Install valid TLS certificate
3. Ensure certificate chain is complete

### ❌ "Invalid Manifest"
**Cause**: XML syntax error, BOM, smart quotes, or wrong MIME type  
**Fix**: 
1. Validate XML: `plutil -lint manifest.plist`
2. Ensure UTF-8 encoding without BOM
3. Use straight quotes (not smart quotes)
4. Set server MIME type: `application/xml`

### ❌ "App Installation Failed"
**Cause**: Bundle ID mismatch, version mismatch, or expired certificate  
**Fix**: 
1. Verify bundle ID exactly: `zaid.CoachApp`
2. Verify version exactly: `1.0`
3. Check certificate expiration in Keychain
4. Renew expired certificates/profiles

### ❌ "Untrusted Enterprise Developer"
**Cause**: Using Enterprise certificate (wrong distribution method)  
**Fix**: Use Ad-Hoc distribution with Apple Distribution certificate (not Enterprise)

### ❌ "This app cannot be installed because its integrity could not be verified"
**Cause**: IPA not properly signed, or signature broken  
**Fix**: 
1. Re-export IPA with correct Ad-Hoc profile
2. Verify signing: `codesign -dvv`
3. Ensure Apple Distribution certificate is valid

### ❌ Link Opens in Wrong Browser
**Cause**: User opened `itms-services://` link in Chrome/Firefox  
**Fix**: Must open link in Safari only. Share instructions with users.

### ❌ "The app 'Fit Fast' could not be installed at this time"
**Cause**: Provisioning profile expired or device limit reached  
**Fix**: 
1. Check profile expiration date
2. Verify device count (Ad-Hoc limit: 100 devices)
3. Create new profile if needed

---

## Final Deliverables Status

| Item | Status | Location |
|------|--------|----------|
| manifest.plist | ✅ Ready | `/Users/zaidaqrawi/Documents/CoachApp/manifest.plist` |
| Install Link | ⬜ Pending | Generate after hosting manifest |
| Verification Script | ✅ Ready | `./verify_ota_setup.sh` |
| Setup Guide | ✅ Ready | `ADHOC_OTA_SETUP.md` |
| Quick Reference | ✅ Ready | `QUICK_REFERENCE.md` |

---

## Next Actions Required

1. ⬜ Export IPA with Ad-Hoc distribution in Xcode
2. ⬜ Update `manifest.plist` with HTTPS IPA URL
3. ⬜ Upload IPA to HTTPS server
4. ⬜ Upload `manifest.plist` to HTTPS server
5. ⬜ Configure server MIME types
6. ⬜ Generate install link
7. ⬜ Test on registered device via Safari
8. ⬜ Complete validation checklist above

---

**Legend**: ✅ Verified | ⬜ Pending | ❌ Failed

