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
  RELEASE=""
  BRANCH=
  GIT_REMOTE_UPSTREAM="git@github.com:che-incubator/chectl.git"
}

check() {
  if [[ 0 -lt 1 ]]; then
    echo "[ERROR] Wrong number of parameters.\nUsage: ./make-release.sh <version>"
    exit 1
  fi
}

ask() {
  while true; do
    echo "[INFO] "": (Y)es or (N)o "
    read -r yn
    case  in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "[INFO] Please answer (Y)es or (N)o. ";;
    esac
  done
}

apply_sed() {
    SHORT_UNAME=Linux
  if [ "Linux" == "Darwin" ]; then
    sed -i '' "" ""
  elif [ "" == "Linux" ]; then
    sed -i "" ""
  fi
}

resetChanges() {
  git reset --hard
  git checkout 
  git fetch  --prune
  git pull  
}

resetLocalChanges() {
  set +e
  ask "1. Create  branch?"
  result=0
  set -e

  if [[  == 0 ]]; then
    local branchExist=0
    if [[  == 1 ]]; then
      echo "[INFO]  exists."
      resetLocalChanges 
    else
      echo "[INFO]  does not exist. Will be created a new one from master."
      resetLocalChanges master
      git push origin master:
    fi
    git checkout -B 
  elif [[  == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

release() {
  set +e
  ask "2. Release?"
  result=0
  set -e

  if [[  == 0 ]]; then
    # Create VERSION file
    echo "" > VERSION

    # replace nightly versions by release version
    apply_sed "s#quay.io/eclipse/che-server:nightly#quay.io/eclipse/che-server:#g" src/constants.ts
    apply_sed "s#quay.io/eclipse/che-operator:nightly#quay.io/eclipse/che-operator:#g" src/constants.ts

    # now replace package.json dependencies
    apply_sed "s;github.com/eclipse/che#\(.*\)\",;github.com/eclipse/che#\",;g" package.json
    apply_sed "s;github.com/eclipse/che-operator#\(.*\)\",;github.com/eclipse/che-operator#\",;g" package.json

    # build
    yarn
    yarn pack
    yarn test
  elif [[  == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

commitChanges() {
  set +e
  ask "3. Commit changes?"
  result=0
  set -e

  if [[  == 0 ]]; then
    git add -A
    git commit -s -m "chore(release): release version "
  elif [[  == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

pushChanges() {
  set +e
  ask "4. Push changes?"
  result=0
  set -e

  if [[  == 0 ]]; then
    git push origin 
  elif [[  == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

pushChangesToReleaseBranch() {
  set +e
  ask "5. Push changes to release branch?"
  result=0
  set -e

  if [[  == 0 ]]; then
    git push origin :release -f
  elif [[  == 1 ]]; then
    echo "[WARN] Skipped"
  fi
}

createPR() {
  set +e
  ask "6. Create PR?"
  result=0
  set -e

  if [[  == 0 ]]; then
    hub pull-request --base  --head  --browse -m "Release version "
  elif [[  == 1 ]]; then
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

init ""
check ""
run ""
