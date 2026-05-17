#!/bin/bash
set -e

# Configuration
QT_PATH="${1:-$HOME/Qt/6.8.3/macos}"
BUILD_DIR="build-release"
APP_NAME="NinjaView"
BUNDLE_PATH="${BUILD_DIR}/src/${APP_NAME}.app"

echo "==> Using Qt at: ${QT_PATH}"
if [ ! -d "${QT_PATH}" ]; then
    echo "Error: Qt path not found."
    exit 1
fi

# Clean up
echo "==> Cleaning old build..."
rm -rf "${BUILD_DIR}"

# Configure
echo "==> Configuring Universal Build (x86_64 + arm64)..."
# Workaround: AGL framework is missing in modern macOS SDKs but required by Qt 6.8's FindWrapOpenGL.
# We redirect it to OpenGL framework which is still present and usually sufficient.
cmake -S . -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${QT_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="12.0" \
    -DWrapOpenGL_AGL="-framework OpenGL"

# Build
echo "==> Building..."
cmake --build "${BUILD_DIR}" -j$(sysctl -n hw.ncpu)

# Bundle
echo "==> Bundling with macdeployqt..."
"${QT_PATH}/bin/macdeployqt" "${BUNDLE_PATH}" \
    -qmldir=src/qml \
    -qmldir=Kaakao/src \
    -always-overwrite

# Sign
echo "==> Signing bundle..."
codesign --force --deep --sign - "${BUNDLE_PATH}"

# Verify
echo "==> Verifying Architectures..."
file "${BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"

echo "==> Running Self-Test..."
"${BUNDLE_PATH}/Contents/MacOS/${APP_NAME}" --selftest

echo "=========================================================="
echo " SUCCESS: ${BUNDLE_PATH} is ready."
echo "=========================================================="
