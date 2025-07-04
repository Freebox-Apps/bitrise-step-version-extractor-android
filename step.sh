#!/bin/bash

MODULE=$build_gradle_module
TASK_NAME="printVersionInfo"
GROOVY_FILE="$MODULE/build.gradle"
KTS_FILE="$MODULE/build.gradle.kts"

# Detect which build file to modify
if [[ -f "$GROOVY_FILE" ]]; then
  BUILD_FILE="$GROOVY_FILE"
  SCRIPT_TYPE="groovy"
elif [[ -f "$KTS_FILE" ]]; then
  BUILD_FILE="$KTS_FILE"
  SCRIPT_TYPE="kotlin"
else
  echo "| ❌ No build.gradle or build.gradle.kts file found in module '$MODULE'."
  exit 1
fi

echo "| Detected: $SCRIPT_TYPE DSL"

# Backup the original file
ORIGINAL_FILE="$BUILD_FILE.bak_script"
cp "$BUILD_FILE" "$ORIGINAL_FILE"

# Add the temporary task
echo "| Temporarily adding task $TASK_NAME to $BUILD_FILE..."

if [[ "$SCRIPT_TYPE" == "groovy" ]]; then
  cat <<EOF >> "$BUILD_FILE"

task $TASK_NAME {
    doLast {
        println("VERSION_NAME=\${android.defaultConfig.versionName}")
        println("VERSION_CODE=\${android.defaultConfig.versionCode}")
    }
}
EOF

elif [[ "$SCRIPT_TYPE" == "kotlin" ]]; then
  cat <<EOF >> "$BUILD_FILE"

tasks.register("$TASK_NAME") {
    doLast {
        println("VERSION_NAME=\${android.defaultConfig.versionName}")
        println("VERSION_CODE=\${android.defaultConfig.versionCode}")
    }
}
EOF
fi

# Run the task
echo "| Running ./gradlew :$MODULE:$TASK_NAME"
VERSION_OUTPUT=$(./gradlew :$MODULE:$TASK_NAME --quiet --warning-mode=none)

VERSION_NAME=$(echo "$VERSION_OUTPUT" | grep VERSION_NAME | cut -d'=' -f2)
VERSION_CODE=$(echo "$VERSION_OUTPUT" | grep VERSION_CODE | cut -d'=' -f2)

echo "| "
echo "| Extracted info:"
echo "|     → Version Name: ${VERSION_NAME}"
echo "|     → Version Code: ${VERSION_CODE}"
echo "| "

envman add --key EXTRACTED_ANDROID_VERSION_NAME --value $VERSION_NAME
envman add --key EXTRACTED_ANDROID_VERSION_CODE --value $VERSION_CODE

# Restore the original file
echo "| Restoring original file..."
cp "$ORIGINAL_FILE" "$BUILD_FILE"
rm "$ORIGINAL_FILE"

echo "| Completed successfully."