#!/bin/bash

set -e

echo
echo "  'Nightly Merge Action' is using the following input:"
echo "    - staging_branch = '$INPUT_STAGING_BRANCH'"
echo "    - user_name = $INPUT_USER_NAME"
echo "    - user_email = $INPUT_USER_EMAIL"
echo "    - push_token = $INPUT_PUSH_TOKEN = ${!INPUT_PUSH_TOKEN}"
echo "    - github repository = $GITHUB_REPOSITORY"
echo

if [[ -z "${!INPUT_PUSH_TOKEN}" ]]; then
  echo "Set the ${INPUT_PUSH_TOKEN} env variable."
  exit 1
fi

git config --global --add safe.directory '*'

git remote set-url origin https://x-access-token:${!INPUT_PUSH_TOKEN}@github.com/$GITHUB_REPOSITORY.git
git config --global user.name "$INPUT_USER_NAME"
git config --global user.email "$INPUT_USER_EMAIL"

echo "Deinit all submodules..."
git submodule deinit --all -f

# Configure git to not fetch submodules automatically
git config --global fetch.recurseSubmodules no

echo "Init all submodules..."
git submodule init

echo "Update submodules..."
# Get list of submodules and handle each one individually
git config --file .gitmodules --get-regexp path | while read path_key path; do
    echo "Processing submodule: $path"
    git submodule update --init --force "$path" || echo "Warning: Failed to update $path, continuing..."
done

# Fetch only the main repository
git -c fetch.recurseSubmodules=no fetch --all --tags --prune

INPUT_DEVELOPMENT_BRANCH=$(git branch -r | grep 'release' | tail -n 1 | sed -e "s/origin\///" | tr -d ' ')

echo
echo "DEVELOPMENT BRANCH = $INPUT_DEVELOPMENT_BRANCH"
echo

set -o xtrace

git fetch origin $INPUT_DEVELOPMENT_BRANCH
(git checkout $INPUT_DEVELOPMENT_BRANCH && git pull origin $INPUT_DEVELOPMENT_BRANCH) || git checkout -b $INPUT_DEVELOPMENT_BRANCH origin/$INPUT_DEVELOPMENT_BRANCH

git fetch origin $INPUT_STAGING_BRANCH
(git checkout $INPUT_STAGING_BRANCH && git pull origin $INPUT_STAGING_BRANCH) || git checkout -b $INPUT_STAGING_BRANCH origin/$INPUT_STAGING_BRANCH

if git merge-base --is-ancestor $INPUT_DEVELOPMENT_BRANCH $INPUT_STAGING_BRANCH; then
  echo "No merge is necessary"
  exit 0
fi;

set +o xtrace
echo
echo "  'Nightly Merge Action' is trying to push force the '$INPUT_DEVELOPMENT_BRANCH' branch ($(git log -1 --pretty=%H $INPUT_DEVELOPMENT_BRANCH))"
echo "  into the '$INPUT_STAGING_BRANCH' branch ($(git log -1 --pretty=%H $INPUT_STAGING_BRANCH))"
echo
set -o xtrace

# Delete the current local version of the staging branch

git checkout $INPUT_DEVELOPMENT_BRANCH
git branch -D $INPUT_STAGING_BRANCH

# Create locally the new staging branch at the same level than the development branch
git checkout -b $INPUT_STAGING_BRANCH

# Push force the branch
git push --force origin $INPUT_STAGING_BRANCH
