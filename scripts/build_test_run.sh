#!/bin/sh
if [ ! -d "scripts" ]; then
    echo "Warning: This script should be run from the project root."
fi

if [ ! -d "build" ]; then
    mkdir -p build
    cmake -S . -B build
fi

# Build
cmake --build build -j12

# Run tests
ctest --test-dir build/tests --output-on-failure

# Run
build/src/QuickPreviewApp 