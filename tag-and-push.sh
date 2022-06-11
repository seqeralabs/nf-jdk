#!/bin/bash
# Tag and and push the the GitHub repo and Docker images
#
# - The tag is taken from the `version` in the `build.gradle` file
# - The tagging is enabled using putting the string `[release]` in the
#   commit comment
# - Use the string `[force release]` to override existing tag/images
#
set -e
set -x
SED=sed 
[[ $(uname) == Darwin ]] && SED=gsed
# check for [release] [force] and [enterprise] string in the commit comment
FORCE=${FORCE:-$(git show -s --format='%s' | $SED -rn 's/.*\[(force)\].*/\1/p')}
RELEASE=${RELEASE:-$(git show -s --format='%s' | $SED -rn 's/.*\[(release)\].*/\1/p')}
REMOTE=https://oauth:$GITHUB_TOKEN@github.com/${GITHUB_REPOSITORY}.git

if [[ $RELEASE ]]; then
  TAG=v$(cat VERSION)
  [[ $FORCE == 'force' ]] && FORCE='-f'

   # tag repo
  COMMIT_ID=$(git rev-parse --short HEAD)
  TAG=${TAG}_${COMMIT_ID}

  git tag $TAG $FORCE
  git push $REMOTE $TAG $FORCE

  # push images
  make push
fi
