#!/usr/bin/env bash
set -e

echo "=== 1. Generating Xcode Project via XcodeGen ==="
brew install xcodegen || true
xcodegen generate

echo "=== 2. Building Unsigned Release Archive ==="
mkdir -p build

xcodebuild archive \
  -project "LightNovelReader.xcodeproj" \
  -scheme "LightNovelReader" \
  -configuration Release \
  -archivePath "build/LightNovelReader.xcarchive" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

echo "=== 3. Packaging Unsigned IPA File ==="
mkdir -p "build/Payload"
cp -R "build/LightNovelReader.xcarchive/Products/Applications/LightNovelReader.app" "build/Payload/"

cd build
zip -r "app.ipa" "Payload"
cd ..

echo "=== Unsigned IPA Build Completed Successfully! ==="
