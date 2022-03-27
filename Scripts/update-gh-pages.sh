#!/bin/bash

set -o nounset
set -o errexit

# Get script
SCRIPTS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_ROOT_PATH="${SCRIPTS_PATH}/.."
GH_PAGES_WORKTREE="gh-pages-worktree"
GH_PAGES_WORKTREE_PATH="${REPO_ROOT_PATH}/${GH_PAGES_WORKTREE}"
GH_PAGES_BRANCH="gh-pages"

# Go to repo root
cd ${REPO_ROOT_PATH}

# Remove existing worktree
if [[ -e ${GH_PAGES_WORKTREE_PATH} ]]; then
    git worktree remove ${GH_PAGES_WORKTREE} --force
fi

# Create new worktree
git fetch
git worktree add ${GH_PAGES_WORKTREE} --checkout origin/${GH_PAGES_BRANCH}

# Generate documentation
export DOCC_JSON_PRETTYPRINT="YES"
swift package generate-documentation \
    --target SshClient \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path SshClient \
    --output-path ${GH_PAGES_WORKTREE_PATH}/docs

# Commit and push changes
COMMIT_HASH=$(git rev-parse --short HEAD)
cd ${GH_PAGES_WORKTREE_PATH}
git add docs

if [ -n "$(git status --porcelain)" ]; then
    echo "Commiting changes to the 'gh-pages' branch and pushing to origin."
    git commit -m "docs/ generated from '${COMMIT_HASH}'."
    git push origin HEAD:${GH_PAGES_BRANCH}
else
  echo "No documentation changes found."
fi

