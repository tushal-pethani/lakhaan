#!/bin/bash

# generate_appcast.sh
# Usage: ./generate_appcast.sh [version]
# If no version provided, reads from pubspec.yaml

set -e

# Get version from pubspec.yaml if not provided
if [ -z "$1" ]; then
    if [ -f "pubspec.yaml" ]; then
        VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
    else
        echo "Error: pubspec.yaml not found and no version provided"
        exit 1
    fi
else
    VERSION="$1"
fi

# Get current date in RFC 822 format
DATE=$(date -u '+%a, %d %b %Y %H:%M:%S GMT')

# Create appcast.xml from template
sed -e "s/{{VERSION}}/$VERSION/g" \
    -e "s/{{DATE}}/$DATE/g" \
    scripts/appcast.xml.template > appcast.xml

echo "Generated appcast.xml with version $VERSION"
