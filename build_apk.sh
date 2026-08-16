#!/bin/bash
set -e

flutter build apk --debug --split-per-abi

# 16KB page-size alignment for Android 15+ compatibility
SDK_DIR="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
BUILD_TOOLS=$(ls -d "$SDK_DIR"/build-tools/* | sort -V | tail -1)
ZIPALIGN="$BUILD_TOOLS/zipalign"
APK_DIR="build/app/outputs/flutter-apk"

if [ -f "$ZIPALIGN" ]; then
  for apk in "$APK_DIR"/*-release.apk; do
    [ -f "$apk" ] || continue
    name=$(basename "$apk")
    echo "Aligning $name to 16KB page size..."
    "$ZIPALIGN" -f -P 16 16 "$apk" "${apk}.tmp"
    mv "${apk}.tmp" "$apk"
    echo "Verifying..."
    "$ZIPALIGN" -c -P 16 16 "$apk"
    echo "16KB alignment OK"
  done
fi

echo ""
echo "Output APKs:"
ls -lh "$APK_DIR"/*-release.apk 2>/dev/null

# Remove old universal APK if present
rm -f "$APK_DIR"/app-release.apk
