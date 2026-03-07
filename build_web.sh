#!/bin/bash

# Load the environment variables from the .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found"
  exit 1
fi

# Build for web using the environment variables
flutter build web \
  --dart-define=X_API_KEY="$X_API_KEY" \
  --dart-define=X_API_SECRET="$X_API_SECRET" \
  --dart-define=APP_SECRET_KEY="$APP_SECRET_KEY"

echo "Build complete."
