# Ad-Hoc OTA Installation - Quick Reference

## Project Details
- **App Name**: Fit Fast
- **Bundle ID**: `zaid.CoachApp`
- **Version**: `1.0`
- **Build**: `1`
- **Team ID**: `K68WL5DJCM`

---

## Files Created

1. **manifest.plist** - OTA manifest (update IPA_URL before use)
2. **verify_ota_setup.sh** - Verification script
3. **ADHOC_OTA_SETUP.md** - Complete setup guide

---

## Quick Start

### 1. Export IPA (Ad-Hoc)
```
Xcode → Product → Archive → Distribute App → Ad Hoc
```

### 2. Update manifest.plist
Replace `REPLACE_WITH_HTTPS_IPA_URL` with your HTTPS IPA URL

### 3. Upload Files
- Upload `CoachApp.ipa` to HTTPS server
- Upload `manifest.plist` to HTTPS server

### 4. Generate Install Link
```
itms-services://?action=download-manifest&url=https://yourdomain.com/manifest.plist
```

### 5. Test
Open link in Safari on registered device

---

## Verification

```bash
# Validate manifest
plutil -lint manifest.plist

# Run full verification
./verify_ota_setup.sh [IPA_PATH] [MANIFEST_PATH]
```

---

## Critical Requirements

✅ Device UDID registered in provisioning profile  
✅ Ad-Hoc provisioning profile (not Development/Enterprise)  
✅ Apple Distribution certificate (not Development)  
✅ HTTPS hosting (HTTP will fail)  
✅ Correct MIME types (.plist → application/xml, .ipa → application/octet-stream)  
✅ Bundle ID exactly matches: `zaid.CoachApp`  
✅ Version exactly matches: `1.0`  

---

## Install Link Format
```
itms-services://?action=download-manifest&url=[HTTPS_MANIFEST_URL]
```

**Must open in Safari** (not Chrome/Firefox)

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Unable to Download App" | UDID not in profile | Add device, regenerate profile, re-export |
| "Cannot Connect" | HTTP or invalid cert | Use HTTPS with valid TLS |
| "Invalid Manifest" | XML error or wrong MIME | Validate XML, set correct MIME type |
| "Installation Failed" | Bundle/version mismatch | Verify exact match |
| Opens in wrong browser | Not Safari | Must use Safari |

---

## Server MIME Types

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
}
```

---

**For detailed instructions, see ADHOC_OTA_SETUP.md**

