#!/bin/bash

# The Lepton image comes in one of two build profiles:
#
#   game    - the default.  Trimmed image, tuned for running Android games under
#             Steam (single-app container, process observer shuts it down when
#             the app exits).
#
#   general - stock-ish AOSP image that keeps the system packages and services
#             usually trimmed by Lepton, for running general Android
#             applications in a persistent container (e.g. `lepton start general`).
#
# The active profile is decided by, in order of precedence:
#   1. The LEPTON_PROFILE environment variable (set implicitly when launching
#      the `general` context, or explicitly by the build/CI tooling).
#   2. The `profile` marker file shipped next to the installed image
#      (`compat_tool/images/profile`), which package_rootfs.sh writes.
#   3. Defaulting to "game".

function lepton_profile()
{
    if [[ -n "${LEPTON_PROFILE:-}" ]]; then
        echo -n "${LEPTON_PROFILE}"
    elif [[ -f "${LEPTON_DIR}/../images/profile" ]]; then
        cat "${LEPTON_DIR}/../images/profile"
    else
        echo -n "game"
    fi
}

function is_general()
{
    [[ "$(lepton_profile)" == "general" ]]
}

function is_game()
{
    ! is_general
}

# Return the absolute path of the deployed Android rootfs for the active
# profile.  Each profile lives in its own directory so both images can be
# installed side by side without clobbering each other.
function rootfs_path()
{
    if is_general; then
        echo -n "${LEPTON_DIR}/../images/rootfs-general"
    else
        echo -n "${LEPTON_DIR}/../images/rootfs"
    fi
}