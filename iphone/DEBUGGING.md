# iOS Debugging Notes

This file documents recurring issues and their fixes to avoid repeated debugging sessions.

---

## Resolved Issues

### Issue: CreateButtonView Freezes When Opening

**Status:** RESOLVED (2026-01-26)

**Symptom:** The iOS app freezes when the user taps the + button to create a new button. The sheet appears but is completely frozen/unresponsive.

**Root Cause:** Corrupted Xcode build cache combined with accumulated code complexity. The view rendered correctly (debug prints showed only 3 body evaluations, not an infinite loop), but the UI was frozen.

**The Fix:**
1. Clean Xcode DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/ButtonLog-*`
2. Restart Xcode
3. Rebuild CreateButtonView from scratch using `NavigationStack` (not `NavigationView`)

**Key Changes:**
- Use `NavigationStack` instead of `NavigationView` in sheets (iOS 16+ best practice)
- Present sheet from `ButtonsView` (closer to the trigger) instead of `MainTabView`
- Keep the view structure clean and simple

**Working CreateButtonView Structure:**
```swift
struct CreateButtonView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var formData = ButtonFormData()
    @State private var isLoading = false

    var body: some View {
        NavigationStack {  // NOT NavigationView
            Form {
                // Sections...
            }
            .navigationTitle("Create Button")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createButton() }
                }
            }
        }
    }
}
```

**Sheet Presentation (in ButtonsView):**
```swift
.sheet(isPresented: $showingCreateButton) {
    CreateButtonView()
}
```

### Attempted Fixes That Did NOT Work (Before the Real Fix)

These were tried before cleaning DerivedData and restarting Xcode:

1. **ForEach with Identifiable Items** - Changed `[String]` to `[IdentifiedChoice]` with UUIDs
2. **Extracted ChoicesSection Component** - Moved choices into separate views
3. **Explicit EnvironmentObject Passing** - Manually passed `.environmentObject(appState)`
4. **NavigationView to NavigationStack** - Changed navigation container type
5. **Removed NavigationStack entirely** - Used plain VStack
6. **fullScreenCover instead of sheet** - Different presentation style
7. **Moved sheet to different parent views** - Tried MainTabView, ButtonsView

None of these worked until DerivedData was cleaned and Xcode was restarted.

### Debugging Methodology That Worked

1. **Isolate the problem**: Replace sheet content with `Text("TEST")` to verify sheet mechanism works
2. **Incremental rebuild**: Start with absolute minimal view (no @State, no @EnvironmentObject)
3. **Add features one at a time**: @State -> @EnvironmentObject -> Form -> Sections -> etc.
4. **Test each addition**: Run the app after each change to identify the breaking point

### Key Learnings

1. **DerivedData corruption is real** - When nothing makes sense, clean DerivedData first
2. **NavigationStack > NavigationView** - Use NavigationStack for sheets on iOS 16+
3. **Debug prints help** - `let _ = print("DEBUG: body")` shows if view is rendering
4. **Infinite loop vs freeze** - 3 body evaluations = not infinite loop, issue is elsewhere
5. **Restart Xcode** - Sometimes necessary after cleaning DerivedData

---

## How to Use This File

When encountering similar issues:
1. Check this file first for known solutions
2. Try cleaning DerivedData and restarting Xcode EARLY in debugging
3. Use incremental testing to isolate the problem
4. Update this file with new findings

---

## Files Involved

- `iphone/ButtonLog/Views/CreateButtonView.swift` - Main view (rebuilt)
- `iphone/ButtonLog/Views/ButtonsView.swift` - Sheet presentation
- `iphone/ButtonLog/Views/MainTabView.swift` - Tab container
- `iphone/ButtonLog/ViewModels/AppState.swift` - State management
- `iphone/ButtonLog/Models/Button.swift` - ButtonFormData, IdentifiedChoice
