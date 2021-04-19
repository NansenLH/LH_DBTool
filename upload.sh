#!/bin/bash

git stash
git pull origin main --tags
git stash pop

podName='LH_DBTool'

VersionString=`grep -E 's.version.*=' $podName.podspec`
VersionNumber=`tr -cd 0-9 <<<"$VersionString"`
NewVersionNumber=$(($VersionNumber + 1))
LineNumber=`grep -nE 's.version.*=' $podName.podspec | cut -d : -f1`

git add .
git commit -am modification
git pull origin main --tags

sed -i "" "${LineNumber}s/${VersionNumber}/${NewVersionNumber}/g" $podName.podspec

echo "current version is ${VersionNumber}, new version is ${NewVersionNumber}"

git commit -am ${NewVersionNumber}
git tag ${NewVersionNumber}
git push origin main --tags

pod repo push PrivateToolPods $podName.podspec --allow-warnings --use-libraries --verbose
pod repo update PrivateToolPods
