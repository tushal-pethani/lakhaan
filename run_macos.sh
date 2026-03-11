#!/bin/bash

# Load the environment variables from the .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found"
  exit 1
fi

# Run for macOS using the environment variables
flutter run -d macos \
  --dart-define=X_API_KEY="$X_API_KEY" \
  --dart-define=X_API_SECRET="$X_API_SECRET" \
  --dart-define=APP_SECRET_KEY="$APP_SECRET_KEY" \
  --dart-define=TWILIO_SID="$TWILIO_SID" \
  --dart-define=TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" \
  --dart-define=TWILIO_FROM="$TWILIO_FROM"
