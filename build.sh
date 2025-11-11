#!/usr/env/bin/bash
# build.sh - Build rat with all features

set -e

echo "Building rat..."
shards install
crystal build main.cr -o rat --release --no-debug

echo "Build complete!"
echo "Binary created: ./rat"
echo ""
echo "Install to /usr/local/bin:"
echo "  sudo cp rat /usr/local/bin/"
echo ""
echo "Or add to PATH:"
echo "  export PATH=\"\$PATH:$(pwd)\""