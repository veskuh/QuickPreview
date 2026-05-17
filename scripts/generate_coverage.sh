#!/bin/bash

# Configuration
BUILD_DIR="build-coverage"
COVERAGE_INFO="coverage.info"
COVERAGE_FILTERED="coverage_filtered.info"
REPORT_DIR="coverage_report"

# Ensure we are in the root directory
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: This script must be run from the project root."
    exit 1
fi

echo "==> Configuring build with coverage flags..."
cmake -S . -B $BUILD_DIR -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="--coverage" -DCMAKE_EXE_LINKER_FLAGS="--coverage"

echo "==> Building project..."
cmake --build $BUILD_DIR -j$(sysctl -n hw.ncpu)

echo "==> Running tests..."
ctest --test-dir $BUILD_DIR --output-on-failure

echo "==> Capturing coverage data..."
# We use --ignore-errors for common issues with different lcov/gcov versions and generated code
lcov --capture --directory $BUILD_DIR --output-file $COVERAGE_INFO \
    --ignore-errors inconsistent,gcov,unsupported,mismatch,format

echo "==> Filtering report..."
lcov --remove $COVERAGE_INFO \
    '/usr/*' \
    '*/3rdparty/*' \
    '*/tests/*' \
    '*/Qt/*' \
    '*/Kaakao/*' \
    '*/v1/*' \
    '*/moc_*' \
    '*/.qt/*' \
    '*/.rcc/*' \
    --output-file $COVERAGE_FILTERED \
    --ignore-errors unused,inconsistent,format

echo "==> Generating HTML report..."
genhtml $COVERAGE_FILTERED --output-directory $REPORT_DIR \
    --ignore-errors inconsistent,format,unused,source,category

echo "=========================================================="
echo " COVERAGE SUMMARY (src/)"
echo "=========================================================="
# Create a temporary info file with only src directory for a clean console summary
lcov --extract $COVERAGE_FILTERED "*/src/*" --output-file coverage_src_only.info --ignore-errors inconsistent,unused,format > /dev/null 2>&1
lcov --list coverage_src_only.info --ignore-errors inconsistent,format
rm coverage_src_only.info
echo "=========================================================="
echo "HTML Report: $REPORT_DIR/index.html"
echo "=========================================================="

# Cleanup intermediate files if requested
# rm $COVERAGE_INFO $COVERAGE_FILTERED
