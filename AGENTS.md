This is a repository for NinjaView. An app for previewing images from SD card, from digital cameras.

Language: C++, Qt, QML for UI
Libraries: Qt6 (6.4.2+, with qtimageformats for WebP), Kaakao component set (submodule) for appearance.

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
  # On Linux:
  ./build/src/ninjaview --selftest

  # On macOS:
  ./build/src/NinjaView.app/Contents/MacOS/NinjaView --selftest
  ```

Features:
- Immersive Fullscreen Preview (double-click image).
- Keyboard navigation (Arrows, Escape).
- Hidden mouse cursor in fullscreen.
- Asynchronous image decoding with caching.
- Classic Mac OS X aesthetic via Kaakao.

Packaging:
- Linux: Uses CPack to generate DEB and RPM packages.
  - Kaakao backing library is packaged under the private app directory (`/usr/lib/ninjaview/`) to avoid system-wide pollution.
  - Kaakaoplugin and QML files are packaged under `/usr/lib/ninjaview/qml/`.
  - In CI, builds are packaged inside stable LTS containers (Ubuntu 24.04 and Fedora 40) to target compatible system-provided Qt6 versions.
- macOS: Uses `macdeployqt` to bundle dependencies inside the standalone `NinjaView.app` bundle.

Engineering Guidelines:
- **Source Control**: ONLY commit or push when specifically requested by the user.
- **Committing**: When a "commit" is requested, perform the git operations strictly. NEVER perform any code changes, formatting, or "cleanups" during the commit phase. All code work must be completed and verified before the commit command is issued.

Documentation:
- Code should have comments suitable for generating documentation using Qt documentation tools
- Tone of voice in user facing documentation like README.md or content in About should be neutral in tone. This is a simple utility, not anything groundbreaking, hence, the voice should without any hype works, or extra fluff. Superlatives should be avoided, bit it's okay to say fast if something is objectively really fast.
