#!/bin/bash
echo "
task(\"printVersion\") {
  doLast {
      println android.defaultConfig.versionName
      println android.defaultConfig.versionCode
  }
}

android.applicationVariants.all { variant ->
    task(\"printVersion\${variant.name.capitalize()}\") {
        doLast {
            println variant.versionName
            println variant.versionCode
        }
    }
}
" >> ${build_gradle_path}

VERSION=$(${gradlew_path} -q printVersion${variant} | tail -n 2)
VERSION_NAME=$(printf "%s\n" $VERSION | sed -n 1p)
VERSION_CODE=$(printf "%s\n" $VERSION | sed -n 2p)
envman add --key EXTRACTED_ANDROID_VERSION_NAME --value $VERSION_NAME
envman add --key EXTRACTED_ANDROID_VERSION_CODE --value $VERSION_CODE

echo "-EXTRACTED_ANDROID_VERSION_NAME: $VERSION_NAME"
echo "-EXTRACTED_ANDROID_VERSION_CODE: $VERSION_CODE"

exit 0
