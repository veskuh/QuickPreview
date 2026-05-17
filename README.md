# NinjaView

NinjaView is a simple C++/Qt6 image viewer designed for rapid previewing of photos, specifically tailored for workflows involving SD cards and digital cameras. It features a classic aesthetic built on the [Kaakao](https://github.com/veskuh/Kaakao) component set.

## Features

- **Fast Previews**: Asynchronous image decoding with intelligent caching for smooth gallery browsing.
- **Fullscreen Mode**: Double-click any image to enter a distraction-free viewing mode.
- **Desktop-First Navigation**: Full keyboard support (Arrow keys for cycling, Escape to exit) and touchpad scrolling.
- **Classic Look**: A faithful recreation of the classic Mac OS X interface using custom QML components.
- **Robust Core**: Written in modern C++17 and Qt6 for performance and stability.

## Getting Started

### Prerequisites

- **Qt 6.6+** (with Core, Gui, Qml, Quick, QuickControls2, Core5Compat, ShaderTools, Concurrent)
- **CMake 3.16+**
- **Compiler**: C++17 capable (Clang, GCC, MSVC)

### Build Instructions

1.  **Clone the repository with submodules**:
    ```bash
    git clone --recursive git@github.com:veskuh/NinjaView.git
    cd NinjaView
    ```

2.  **Configure and Build**:
    ```bash
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j12
    ```

3.  **Run the application**:
    ```bash
    # On macOS:
    open build/src/NinjaView.app
    
    # On Linux:
    ./build/src/ninjaview
    ```

## Development

### Testing

The project includes both C++ unit tests and QML UI tests.

```bash
# Run all tests
ctest --test-dir build/tests --output-on-failure

# Run a self-diagnostic check
./build/src/ninjaview --selftest
```

### Project Structure

- `src/core/`: Backend logic and image discovery.
- `src/ui/`: C++ ViewModels and Image Providers.
- `src/qml/`: High-performance UI components.
- `tests/`: Comprehensive test suite.
- `Kaakao/`: The UI component library submodule.

## CI/CD

NinjaView uses GitHub Actions for continuous integration, automatically validating builds and running tests on Ubuntu 24.04 for every pull request and commit.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
