#!/usr/bin/env bash

if [ $TRAVIS_OS_NAME == "osx" ]; then
  PROJ_OUTPUT=`swift package generate-xcodeproj`;
  PROJ_NAME="${PROJ_OUTPUT/generated: .\//}"
  SCHEME_NAME="${PROJ_NAME/.xcodeproj/}-Package"
  rvm install 2.2.3
  gem install xcpretty
  WORKING_DIRECTORY=$(PWD)
  xcodebuild -project $PROJ_NAME -scheme $SCHEME_NAME -sdk macosx10.13 -destination arch=x86_64 -configuration Debug -enableCodeCoverage YES test | xcpretty
  bash <(curl -s https://codecov.io/bash)
fi
