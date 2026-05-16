This is a repository for QuickPreview. An app for previewing images from SD card, from digital cameras.

Language: C++, Qt, QML for UI
Libraries: Qt6, Kaakao component set (submodule) for appearance.

Target platforms: Mac (x86 & arm), Linux (x86)

Project Structure:
- `src/`: Main application source code.
  - `src/core/`: Backend logic, image processing, and hardware integration.
  - `src/ui/`: C++ ViewModels and UI controllers.
  - `src/qml/`: QML files for the user interface.
- `Kaakao/`: UI Component library (git submodule).

Building: 
```bash
git submodule update --init --recursive
cmake -S . -B build
cmake --build build -j12
```

Testing:
- Unit tests for native code (in development)
- UI tests for QML (utilizing Kaakao test patterns)
- Self-check: Run the application with `--selfcheck` to verify all views and components load properly.
  ```bash
  ./build/src/QuickPreviewApp --selfcheck
  ```

Look:
- Classic Mac OS X look, as defined in Kaakao components.
- Consistent with Aqua/Platinum aesthetics.
