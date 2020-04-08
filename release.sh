#!/bin/bash
#
# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

set -e
set -u

init() {
  RELEASE="$1"
  BRANCH=$(echo $RELEASE | sed 's/.$/x/')
  GIT_REMOTE_UPSTREAM="git@github.com:che-incubator/chectl.git"
}

check() {
  if [[ $# -lt 1 ]]; then
    echo "[ERROR] Wrong number of parameters.\nUsage: ./make-release.sh <version>"
    exit 1
  fi
}

ask() {
  while true; do
    echo -n "[INFO] "$@": (Y)es or (N)o "
    read -r yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "[INFO] Please answer (Y)es or (N)o. ";;
    esac
  done
}

apply_sed() {
    SHORT_UNAME=$(uname -s)
  if [ "$(uname)" == "Darwin" ]; then
    sed -i '' "$1" "$2"
  elif [ "${SHORT_UNAME:0:5}" == "Linux" ]; then
    sed -i "$1" "$2"
  fi
}

resetChanges() {
  git reset --hard
  git checkout $1
  git fetch ${GIT_REMOTE_UPSTREAM} --prune
  git pull ${GIT_REMOTE_UPSTREAM} $1
}

resetLocalChanges() {
  set +e
  ask "1. Create $BRANCH branch?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    local branchExist=$(git ls-remote -q --heads | grep $BRANCH | wc -l)
    if [[ $branchExist == 1 ]]; then
      echo "[INFO] $BRANCH exists."
      resetLocalChanges $BRANCH
    else
      echo "[INFO] $BRANCH does not exist. Will be created a new one from master."
      resetLocalChanges master
      git push origin master:$BRANCH
    fi
    git checkout -B $RELEASE
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

release() {
  set +e
  ask "2. Release?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    # Create VERSION file
    echo "$RELEASE" > VERSION

    # replace nightly versions by release version
    apply_sed "s#quay.io/eclipse/che-server:nightly#quay.io/eclipse/che-server:${RELEASE}#g" src/constants.ts
    apply_sed "s#quay.io/eclipse/che-operator:nightly#quay.io/eclipse/che-operator:${RELEASE}#g" src/constants.ts

    # now replace package.json dependencies
    apply_sed "s;github.com/eclipse/che#\(.*\)\",;github.com/eclipse/che#${RELEASE}\",;g" package.json
    apply_sed "s;github.com/eclipse/che-operator#\(.*\)\",;github.com/eclipse/che-operator#${RELEASE}\",;g" package.json

    # build
    yarn
    yarn pack
    yarn test
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

commitChanges() {
  set +e
  ask "3. Commit changes?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    git add -A
    git commit -s -m "chore(release): release version ${RELEASE}"
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

pushChanges() {
  set +e
  ask "4. Push changes?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    git push origin $RELEASE
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

pushChangesToReleaseBranch() {
  set +e
  ask "5. Push changes to release branch?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    git push origin $RELEASE:release -f
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

createPR() {
  set +e
  ask "6. Create PR?"
  result=$?
  set -e

  if [[ $result == 0 ]]; then
    hub pull-request --base ${BRANCH} --head ${RELEASE} --browse -m "Release version ${RELEASE}"
  elif [[ $result == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

run() {
  resetLocalChanges
  release
  commitChanges
  pushChanges
  pushChangesToReleaseBranch
  createPR
}

init $@
check $@
run $@
