This is a repository for QuickPreview. An app for previewing images from SD card, from digital cameras.

Language: C++, Qt, QML for UI
Libraries: Qt6, Kaakao component set (submodule) for appearance.

Target platforms: Mac (x86 & arm), Linux (x86)

Project Structure:
- `src/`: Main application source code.
  - `src/core/`: Backend logic, image discovery service.
  - `src/ui/`: C++ Gallery model and image provider.
  - `src/qml/`: QML files (Main window, Fullscreen preview).
- `tests/`: Unit and UI tests (C++ and QML).
- `Kaakao/`: UI Component library (git submodule).

Building: 
```bash
git submodule update --init --recursive
cmake -S . -B build
cmake --build build -j12
```

Testing:
- Unit tests: Verified C++ backend logic (model, discovery, image provider).
- UI tests: Verified QML interactions (navigation, visibility).
- Run all tests:
  ```bash
  ctest --test-dir build/tests --output-on-failure
  ```
- Self-check:
  ```bash
  ./build/src/QuickPreviewApp --selfcheck
  ```

Features:
- Immersive Fullscreen Preview (double-click image).
- Keyboard navigation (Arrows, Escape).
- Hidden mouse cursor in fullscreen.
- Asynchronous image decoding with caching.
- Classic Mac OS X aesthetic via Kaakao.

Engineering Guidelines:
- **Source Control**: ONLY commit or push when specifically requested by the user.
- **Committing**: When a "commit" is requested, perform the git operations strictly. NEVER perform any code changes, formatting, or "cleanups" during the commit phase. All code work must be completed and verified before the commit command is issued.
