#!/usr/bin/env bash
set -e

echo "=== 1. Selecting Xcode Version ==="
if [ -d "/Applications/Xcode_16.0.app" ]; then
  sudo xcode-select -s /Applications/Xcode_16.0.app
elif [ -d "/Applications/Xcode.app" ]; then
  sudo xcode-select -s /Applications/Xcode.app
fi
xcodebuild -version

echo "=== 2. Generating Xcode Project via XcodeGen ==="
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen generate

echo "=== 3. Building Unsigned Release Archive ==="
mkdir -p build

xcodebuild archive \
  -project "LightNovelReader.xcodeproj" \
  -scheme "LightNovelReader" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "build/LightNovelReader.xcarchive" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "=== 4. Packaging Unsigned IPA File ==="
mkdir -p "build/Payload"
cp -R "build/LightNovelReader.xcarchive/Products/Applications/LightNovelReader.app" "build/Payload/"

cd build
zip -r "app.ipa" "Payload"
cd ..

echo "=== Unsigned IPA Build Completed Successfully! ==="
