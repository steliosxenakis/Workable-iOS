# TestFlight: Test Candidate Profile on Real Devices

To install the app on your iPhone/iPad via TestFlight, follow these steps.

## Prerequisites

- **Apple Developer account** (paid program, $99/year) — [developer.apple.com](https://developer.apple.com)
- **Xcode** with your Apple ID signed in
- **App created in App Store Connect** (see Step 2)

---

## Step 1: Configure signing in Xcode

1. Open **CandidateProfile.xcodeproj** in Xcode.
2. Select the **CandidateProfile** project in the left sidebar (blue icon).
3. Select the **CandidateProfile** target.
4. Open the **Signing & Capabilities** tab.
5. Check **"Automatically manage signing"**.
6. Choose your **Team** (your Apple Developer account).  
   - If you don’t see it: **Xcode → Settings → Accounts** → add your Apple ID and ensure it’s in a paid developer program.
7. Set a unique **Bundle Identifier**, e.g. `com.yourcompany.CandidateProfile` (must match the app you create in App Store Connect in Step 2).

---

## Step 2: Create the app in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com) and sign in.
2. **My Apps** → **+** → **New App**.
3. Choose **iOS**, enter:
   - **Name:** e.g. Candidate Profile
   - **Primary Language**
   - **Bundle ID:** pick the same one you set in Xcode (e.g. `com.yourcompany.CandidateProfile`).  
     If it doesn’t exist yet: **Certificates, Identifiers & Profiles** → **Identifiers** → **+** → **App IDs** → register the same bundle ID.
4. Create the app. You don’t need to fill in store listing details yet for TestFlight.

---

## Step 3: Archive and upload the build

1. In Xcode, set the run destination to **"Any iOS Device (arm64)"** (not a simulator).
2. Menu: **Product → Archive**.
3. When the archive finishes, the **Organizer** window opens.
4. Select your archive → **Distribute App**.
5. Choose **App Store Connect** → **Next**.
6. Choose **Upload** → **Next**.
7. Leave options as default (e.g. upload symbols, manage version) → **Next**.
8. Select your **distribution certificate** and **provisioning profile** (Xcode usually picks them) → **Upload**.
9. Wait for the upload to complete.

---

## Step 4: Submit the build to TestFlight

1. In [App Store Connect](https://appstoreconnect.apple.com), open your app.
2. Go to the **TestFlight** tab.
3. Under **iOS**, wait until the build appears (processing can take 5–30 minutes).
4. When it appears, click the build.
5. Fill in **What to Test** (optional but useful).
6. Under **TestFlight** (left sidebar), open **Internal Testing** or **External Testing**:
   - **Internal Testing:** Add testers by email (they must be in your App Store Connect team). They get the build as soon as it’s processed.
   - **External Testing:** Create a group, add testers by email. The first time you add external testers, the build must go through **Beta App Review** (often same day).

---

## Step 5: Install on your device via TestFlight

1. On your iPhone or iPad, install **TestFlight** from the App Store (if needed).
2. Open the **invitation email** from Apple (or use the public link if you created one for external testing).
3. Tap **View in TestFlight** / **Accept** and install the app.
4. Open the app from the home screen or from TestFlight.

---

## Troubleshooting

| Issue | What to do |
|-------|------------|
| No Team in Signing | Add your Apple ID in Xcode → Settings → Accounts; join a paid developer program. |
| Bundle ID already in use | Change it in Xcode and in App Store Connect (new app or edit identifier) so they match. |
| “No accounts with App Store Connect access” | Use an account that has Admin or App Manager role for the app. |
| Build missing in TestFlight | Wait 5–30 min; check **Activity** in App Store Connect for processing/errors. |
| Can’t install on device | Confirm the device is in the correct TestFlight group and that you accepted the invite. |

---

## Quick checklist

- [ ] Apple Developer account ($99/year)
- [ ] Bundle ID set in Xcode and matching App Store Connect
- [ ] Signing & Capabilities → Team selected, automatic signing on
- [ ] Product → Archive with destination “Any iOS Device”
- [ ] Distribute → App Store Connect → Upload
- [ ] TestFlight tab → build processed → Internal or External group
- [ ] Testers get email → install via TestFlight on device
