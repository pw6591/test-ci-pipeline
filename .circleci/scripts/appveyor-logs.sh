#!/bin/bash

set -e

echo "Waiting for AppVeyor to finish uploading Windows installation packages."

repo_name=$(git config --get remote.origin.url | sed 's/.*://' | sed 's/\.git$//')
echo "Retrieve status of AppVeyor job with same $repo_name git commit id $CIRCLE_SHA1"
try=1
max_tries=10
while [ "$appveyor_build" == "" ] && [ $try -le $max_tries ]; do
  echo "Try $try of $max_tries"
  (( try++ ))
  appveyor_build=$(curl -s --fail -H "Authorization: Bearer $APPVEYOR_TOKEN" "https://ci.appveyor.com/api/projects/$repo_name/history?recordsNumber=20" | jq ".builds[] | select(.commitId | contains(\"$CIRCLE_SHA1\"))")
  appveyor_build_number=$(echo "$appveyor_build" | jq .buildNumber)
  if [ "$appveyor_build" == "" ]; then
    echo "No AppVeyor build number for git commit $CIRCLE_SHA1 found"
    sleep 30
  else
    continue
  fi
done

echo "Found AppVeyor build $appveyor_build"

# Wait for AppVeyor build
appveyor_build_status=$(echo "$appveyor_build" | jq -r .status)
while [ "$appveyor_build_status" != "success" ]; do
  if [ "$appveyor_build_status" == "failed" ]; then
    break
  fi
  if [ "$appveyor_build_status" == "cancelled" ]; then
    break
  fi

  echo "Waiting for AppVeyor build $appveyor_build_number to succeed..."
  sleep 30
  appveyor_build=$(curl -s --fail -H "Authorization: Bearer $APPVEYOR_TOKEN" "https://ci.appveyor.com/api/projects/$repo_name/history?recordsNumber=20" | jq ".builds[] | select(.commitId | contains(\"$CIRCLE_SHA1\"))")
  appveyor_build_status=$(echo "$appveyor_build" | jq -r .status)
done

# Show AppVeyor log
appveyor_job_id=$(curl -s --fail -H "Authorization: Bearer $APPVEYOR_TOKEN" "https://ci.appveyor.com/api/projects/$repo_name/build/$appveyor_build_number" | jq -r .build.jobs[0].jobId)
curl --fail -H "Authorization: Bearer $APPVEYOR_TOKEN" "https://ci.appveyor.com/api/buildjobs/$appveyor_job_id/log"

# Abort Circle job if AppVeyor job failed
if [ "$appveyor_build_status" == "failed" ]; then
  echo "AppVeyor build $appveyor_build_number failed"
  exit 10
fi
if [ "$appveyor_build_status" == "cancelled" ]; then
  echo "AppVeyor build $appveyor_build_number cancelled"
  exit 10
fi

