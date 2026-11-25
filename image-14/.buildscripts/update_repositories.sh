#!/bin/bash

set -eo pipefail

ROOT_DIR="$(dirname "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" )"

IS_CI=false
if [[ "${1:-}" == "--ci" ]]; then
    IS_CI=true
    shift
fi

if [ ! -f /run/.containerenv ] && [ ! -f /.dockerenv ]; then
    echo "You must run me inside podman or docker! I do things to git config --global and such, you REALLY don't want me touching your stuff."
    exit 1
fi


# Initialize/Update repositories with `repo`
LEPTON_PROFILE="${LEPTON_PROFILE:-game}"
mkdir -p "${ROOT_DIR}/output"
pushd "${ROOT_DIR}/output" >/dev/null
    REPO_INIT_ARGS=
    if [[ "$IS_CI" == "true" ]]; then
        REPO_INIT_ARGS="--partial-clone --depth=1"
    fi
    if [[ -f .repo/manifest.xml ]]; then
        # Reset each project back to where it was before any patching, so a
        # fresh set of patches can be applied for the requested profile.
        # apply-patches.sh tags projects with `autopatch/*` right after sync.
        repo forall -c '
            AUTOPATCH_TAG=$(git tag -l "autopatch/*" | head -n1)
            if [[ -n "${AUTOPATCH_TAG}" ]]; then
                git reset --hard "${AUTOPATCH_TAG}"
            else
                git reset --hard
            fi
            git clean -ffdx
        ' || true
    else
        repo init $REPO_INIT_ARGS -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r75 -g default,-trusty --git-lfs
    fi

    mkdir -p "${ROOT_DIR}"/output/.repo/local_manifests
    cp "${ROOT_DIR}"/android_vendor_valve/manifest_scripts/manifests-34/*.xml "${ROOT_DIR}"/output/.repo/local_manifests

    # From here on out, use the repo that it itself downloads
    REPO=${ROOT_DIR}/output/.repo/repo/repo

    REPO_SYNC_ARGS=
    if [[ "$IS_CI" == "true" ]]; then
        REPO_SYNC_ARGS="-c"
    fi

    # Generate the `.repo/manifest.xml` file, then sync all projects down
    # We can use a very high parallelism here, because our `--reference` above
    # turns the vast majority of our network I/O into disk I/O.
    if ! ${REPO} sync $REPO_SYNC_ARGS --force-sync --force-checkout --force-remove-dirty -j4; then
        ${REPO} sync $REPO_SYNC_ARGS --force-sync --force-checkout --force-remove-dirty -j1
    fi

    # Copy in vendored projects
    "${ROOT_DIR}/.buildscripts/copy_vendored_projects.sh"

    # Record the profile this tree was synced for, so a profile switch can be
    # detected and re-sync/reset performed automatically.
    echo "${LEPTON_PROFILE}" > "${ROOT_DIR}/output/.lepton_profile"
popd >/dev/null
