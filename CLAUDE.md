# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Building and Running:**
- Use Xcode to build and run the app on iOS simulator or device
- The project uses SwiftUI and targets iOS (minimum version visible in code)
- No additional build tools or dependencies beyond standard iOS SDK

**File Persistence:**
- Generated files are stored in the app's documents directory under `GeneratedOutputs/`
- Metadata is stored in `onebox-files.json` (JSON format)
- To reset data: delete the app from simulator/device or uninstall and reinstall

**Testing:**
- No visible test suite in current codebase
- Manual testing via simulator/device is primary verification method
- Focus on UI interactions and file generation workflows

## Code Architecture

**Overall Structure:**
- **Entry Point**: `OneBoxApp.swift` - SwiftUI app with `ContentView` as root
- **Main UI**: `ContentView.swift` - Tab-based navigation (Home, Tools, Files) with floating action cluster for quick operations
- **Data Layer**: 
  - `Models/AppModels.swift` - Core data structures (QuickOperation, ImportedDocument, ToolCategory, etc.)
  - `Models/OneBoxFileStore.swift` - File persistence system handling PDF/image storage and metadata
- **Screens**:
  - `Screens/HomeScreen.swift` - Main dashboard with recent files and import options
  - `Screens/ToolsScreen.swift` - Tool browser with categories, search, and favorites
  - `Screens/ToolDestinationScreen.swift` - Routes to specific tool implementations based on tool selection
  - Individual tool screens (ImageToPDFToolScreen, CompressPDFToolScreen, etc.)
  - `Screens/DocumentWorkspaceScreen.swift` - Editing workspace for imported documents
- **Services**:
  - `Services/BackgroundRemovalService.swift` - Background removal functionality
  - `Services/PDFCoService.swift` - PDF.co API integration (requires API key in Secrets.plist)
  - `Services/OneBoxSecrets.swift` - Secure API key management via Secrets.plist (gitignored)
- **Components**:
  - `Components/ImportedHeroCard.swift`, `DocumentScannerView.swift`, etc. - Reusable UI components
  - *Note: LiquidGlassStyle.swift has been removed; visual effects now use native SwiftUI materials only.*

## Architectural Guidelines

### 1. UI & Styling Constraints (Native SwiftUI Only)
- **ABSOLUTELY NO** custom Metal shaders, manual coordinate math, or third-party libraries for glassmorphism or visual effects.
- Use **exclusively** native SwiftUI materials (`.ultraThinMaterial`, `.regularMaterial`, `.thinMaterial`, `.thickMaterial`, `.ultraThickMaterial`) and system blurs (`.blur(radius:)`) for any translucent/frosted glass effects.
- **TabView structure in `ContentView.swift` and the Floating Action Button cluster (usage and definition) MUST NOT be altered or removed under any circumstances.
- All visual effects must be achieved through material overlays and blurs only; avoid `Canvas`, `TimelineView`, `Shader`, or manual drawing for UI effects.

### 2. Unified Data Flow & Session Management
- Implement a **strict single-source-of-truth session state** via an observable `SessionState` object (class conforming to `ObservableObject`).
- The session state holds the active imported document (`ImportedDocument?`), selected items (`[ImportSelectionItem]`), and editing status.
- Inject this object into the environment (e.g., via `@StateObject` in `OneBoxApp` or `ContentView`) so all screens can access it.
- **Data Flow Must Be Seamless**:
  * **Flow A (File First)**: When a user taps the ImportedHeroCard on HomeScreen to preview a file, then selects a tool (via quick action, tab, or floating button), that exact file MUST be pre-loaded in the tool screen workspace. The tool receives the active document from session state.
  * **Flow B (Tool First)**: When a user navigates to a specific tool screen first (via Tools tab or floating button) with no active file, the tool shows a clean import area. Importing a file loads it immediately into the tool and updates session state.
- Avoid disjointed state: importing a document on HomeScreen and then clicking a tool must pre-load that document in the tool.

### 3. Professional File Handling Architecture
- **File persistence and editing states** must mirror industry-standard patterns (e.g., Adobe Acrobat, Apple Files).
- `OneBoxFileStore` remains the **source of truth** for persisted files (stored in `GeneratedOutputs/` with metadata in `onebox-files.json`).
- For **active editing**, use temporary files in the app's `caches` directory.
- Implement **explicit save/export states**:
  * **Save**: When user chooses to save, move/copy the temporary file to `OneBoxFileStore` outputs (via `savePDF` or similar) and update metadata.
  * **Export**: Use `ShareLink` or document picker to export the current state to a user-chosen location.
- Support **non-destructive editing contexts**: store editing adjustments (e.g., filter parameters, crop rects) separately alongside the temporary file; apply them on load.
- **Clear temporary cache** on app exit or when an editing session ends (observe `ScenePhase` changes).

### 4. Scalability for Tools
- Keep tool definitions in `AppModels.swift` (`toolCategories` as `[OperationItem]` groups).
- Each tool screen should accept initial items via session state (or parameter), process them, and output via `OneBoxFileStore` save methods.
- Encourage a consistent UI pattern: import area → processing state → output card.
- Provide reusable view modifiers for common tool UI (e.g., loading buttons, status cards).
- When implementing new tool stubs (e.g., `CompressPDFToolScreen`), follow this pattern and register the tool in `toolCategories`.

## Key Patterns (Updated)

1. **State Management**: Uses `@State`, `@AppStorage` (for favorites), `@Environment` for UI state, and `@EnvironmentObject` for the shared `SessionState`.
2. **Navigation**: TabView for main navigation (protected), NavigationStack for deep linking, sheets for modals.
3. **Persistence**: `OneBoxFileStore` handles saving files to disk and maintaining JSON metadata records; temporary files managed separately for active sessions.
4. **Tool System**: Tools defined in `AppModels.swift` as `OperationItem` grouped in `ToolCategory` arrays; accessed via session state for seamless workflow.
5. **UI Styling**: Exclusive use of native SwiftUI materials and system blurs; no custom shaders, manual coordinate math, or third-party libraries.

## Data Flow (Updated)

1. User imports files/photos via HomeScreen (PhotosPicker, file importer, camera) → updates `SessionState` with active document and selected items.
2. Imported items become `ImportSelectionItem` objects stored in session state.
3. When starting a tool (via quick action, tab, or floating button), the tool reads the active document from `SessionState` via `@EnvironmentObject`.
4. Tools process images/data and generate outputs; outputs are saved via `OneBoxFileStore.savePDF()` or similar methods.
5. Saved files appear in HomeScreen recent outputs and FilesScreen; session state may be cleared or updated with new output per app policy.
6. Export/save actions update `OneBoxFileStore` and optionally clear session state.

## Common Modification Points

- **Adding new tools**: Define in `toolCategories` (AppModels.swift), add case in `ToolDestinationScreen.swift` (or rely on session state passing).
- **Modifying persistence**: Update `OneBoxFileStore.swift` (save/load/delete methods); consider adding helpers for temporary file management.
- **Changing UI styling**: **Only** use native SwiftUI material modifiers (`.background(.ultraThinMaterial)`, `.blur(radius:)`, etc.); **do not** modify `LiquidGlassStyle.swift` (it has been removed) or create custom glassmorphism effects.
- **Adding import sources**: Update HomeScreen import options and corresponding handling; ensure imported items update session state.
- **Implementing session state**: Add `SessionState` class (e.g., in `AppModels.swift` or a new file) and inject as `@StateObject` in the app root.
- **Avoid altering protected UI**: Do not modify the `TabView` in `ContentView.swift` or the `FloatingActionCluster` usage/definition.

## Important Files

- `OneBoxFileStore.swift` - Core persistence logic (read before modifying)
- `AppModels.swift` - Central definitions of tools, documents, UI models; **should contain or import** `SessionState`
- `ContentView.swift` - Main app navigation structure; **MUST NOT** alter TabView structure or FloatingActionCluster usage
- `ToolDestinationScreen.swift` - Tool routing logic; reads active document from session state
- `OneBox/AppModels.swift` (or new file) - Location for `SessionState` observable object
- `OneBox/Screens/HomeScreen.swift` - Updates session state on import; reads from session state for preview
- Individual tool screens (e.g., `ImageToPDFToolScreen.swift`) - Verify they use session state for initial items and use only native material effects

## Verification Checklist

When implementing changes, ensure:
- No references to `LiquidGlassStyle`, `glassEffect`, `Shader`, `Canvas`, `TimelineView`, or manual coordinate math for visual effects remain.
- TabView structure in `ContentView.swift` and FloatingActionCluster usage/definition are identical to baseline.
- Session state is correctly injected and accessed via `@EnvironmentObject` in tool screens.
- Importing a file on HomeScreen pre-loads that file in any subsequently launched tool.
- Temporary files are stored in caches directory and cleared appropriately.
- Saved outputs go through `OneBoxFileStore` and appear in recent outputs.
- Visual effects use only `.ultraThinMaterial`, `.regularMaterial`, `.blur(radius:)`, etc.