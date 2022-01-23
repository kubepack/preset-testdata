#!/bin/bash

# Copyright AppsCode Inc. and Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

PR_BRANCH=master
COMMIT_MSG="Update charts"

skip_trigger() {
    while IFS=$': \r\t' read -r -u9 marker v; do
        if [ "$marker" = "/skip-trigger" ]; then
            return 0
        fi
    done 9< <(git show -s --format=%b)
    return 1
}

skip_trigger && {
    echo "Skipped recursive trigger."
    exit 0
}

repo_uptodate() {
    ignorefiles=(stable/index.yaml)
    # https://remarkablemark.org/blog/2017/10/12/check-git-dirty/
    changed=($(git status --porcelain | awk '{print $2}'))
    changed+=("${ignorefiles[@]}")
    # https://stackoverflow.com/a/28161520
    diff=($(echo ${changed[@]} ${ignorefiles[@]} | tr ' ' '\n' | sort | uniq -u))
    return ${#diff[@]}
}

echo "Update chart repo"
# make gen fmt
./hack/scripts/update-repo.sh

if repo_uptodate; then
    echo "Repository is up-to-date."
    exit 0
fi

git add --all
git commit -a -s -m "$COMMIT_MSG" -m "/skip-trigger"
git push -u origin $PR_BRANCH
