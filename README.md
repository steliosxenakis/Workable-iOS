# Candidate Profile – SwiftUI

SwiftUI implementation of the **Candidates browser (Per stage)** screen from the [Figma Candidate profile](https://www.figma.com/design/BDQNEdzck5gKAXRgXaqi73/%F0%9F%93%B1-Candidate-profile?node-id=24597-136049) design.

## Structure

- **`CandidateProfileApp.swift`** – App entry point (`@main`)
- **`Theme/DesignTokens.swift`** – Colors and typography from Figma
- **`Models/Candidate.swift`** – `Candidate` model
- **`Views/CandidatesBrowserView.swift`** – Main screen (nav, filters, list, tab bar)
- **`Views/Components/`**
  - `NavBarView.swift` – Back, title, search bar
  - `SearchBarView` – Search field
  - `FilterBarView.swift` – “Newest first” and “Filters”
  - `TabBarView.swift` – Bottom tabs (Home, Jobs, Employees, Inbox, Settings)
  - `JobHeaderView.swift` – Job title and subtitle row
  - `CandidateCardView.swift` – Candidate row with avatar, match %, details
  - `BrowserSwitchView` – Timeline vs list toggle

## How to run

1. In Xcode: **File → New → Project**, choose **App** (iOS).
2. Set **Interface** to **SwiftUI**, **Language** to **Swift**, and **Minimum Deployments** to **iOS 15** (or 17).
3. Delete the default `ContentView.swift` if you don’t need it.
4. Add the `CandidateProfile` folder to the project (drag it into the project navigator, or **File → Add Files to “[Your App]”**).
5. In the app target, set **Main Interface** to **SwiftUI** and ensure the app uses the SwiftUI lifecycle (default for new apps).
6. In the app entry file (e.g. `YourAppApp.swift`), replace the body with:
   ```swift
   CandidatesBrowserView()
   ```
   Or keep your existing `@main` struct and only change the root view to `CandidatesBrowserView()`.
7. Build and run (⌘R).

## Design tokens (from Figma)

- **Background:** `#F8F5F2`
- **Primary (teal):** `#00756A` / `#00665B`
- **Surface:** white, tab bar `#FCF9F7`
- **Separator:** `#EEEDEC`
- **Font default:** `#323234`, secondary `#8A8986`
- **AI accent:** `#8736DC`, background `#FBF4FF`
- **Typography:** SF Pro Text (system font) – headline 17pt semibold, body 17pt, footnote 13pt, etc.
