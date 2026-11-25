#!/bin/bash

CI_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="${CI_DIR}/../"

# The profile determines which rootfs directory ends up in the tarball:
# `images/rootfs` for game, `images/rootfs-general` for general.  `images/profile`
# is shipped alongside so the compat tool knows what was installed.
LEPTON_PROFILE="${LEPTON_PROFILE:-game}"
ROOTFS_DIR_NAME="rootfs"
if [[ "${LEPTON_PROFILE}" == "general" ]]; then
    ROOTFS_DIR_NAME="rootfs-general"
fi

"${PROJECT_DIR}/image-14/.buildscripts/package_rootfs.sh"

mkdir -p "install-rootfs/images/${ROOTFS_DIR_NAME}"
cp -ra "${PROJECT_DIR}"/compat_tool/images/${ROOTFS_DIR_NAME}/* "install-rootfs/images/${ROOTFS_DIR_NAME}"
cp -ra "${PROJECT_DIR}"/compat_tool/images/NOTICE.txt install-rootfs/images
cp -ra "${PROJECT_DIR}"/image-14/version.txt install-rootfs/images
cp -ra "${PROJECT_DIR}"/compat_tool/images/profile install-rootfs/images

tar --zstd -cf "${PROJECT_DIR}"/rootfs.tar.zst -C install-rootfs .