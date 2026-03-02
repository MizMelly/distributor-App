#!/bin/bash

# Exit immediately if a command fails
set -e

# Ensure Flutter is installed and the latest stable channel is used
flutter channel stable
flutter upgrade

# Get dependencies
flutter pub get

# Build Flutter web
flutter build web

# Copy the build output to the root (Vercel expects files in the root or specify output dir)
cp -r build/web/* .