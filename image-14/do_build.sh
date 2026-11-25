#!/bin/bash

ROOT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Profile selection: `--profile game` (the default) or `--profile general`.
# The profile decides which packages are kept and which system_server services
# stay trimmed (see android_vendor_valve/patches/apply-patches.sh and
# android_device_valve_lepton/remove_packages/Android.mk).
export LEPTON_PROFILE="${LEPTON_PROFILE:-game}"

BUILD_ARGS=()
DO_UPDATE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            LEPTON_PROFILE="$2"
            export LEPTON_PROFILE
            shift 2
            ;;
        --profile=*)
            LEPTON_PROFILE="${1#--profile=}"
            export LEPTON_PROFILE
            shift
            ;;
        --update)
            DO_UPDATE=true
            shift
            ;;
        *)
            BUILD_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ "${LEPTON_PROFILE}" != "game" && "${LEPTON_PROFILE}" != "general" ]]; then
    echo "Invalid profile '${LEPTON_PROFILE}' (expected 'game' or 'general')." >&2
    exit 1
fi

echo "Building Lepton image for profile: ${LEPTON_PROFILE}"

if ! podman image exists lepton-builder; then
    podman build -t lepton-builder builder_image -v ${ROOT_DIR}/../:/workdir
fi

if [[ ! -f "${ROOT_DIR}/.buildscripts/.bashrc" ]]; then
    echo "Baking .bashrc..."
    "${ROOT_DIR}/.buildscripts/bake_bashrc.sh"
fi

if [[ "${DO_UPDATE}" == "true" ]]; then
    "${ROOT_DIR}/.buildscripts/container.sh" "./.buildscripts/update_repositories.sh"
fi

if [[ ${#BUILD_ARGS[@]} -gt 0 ]]; then
    "${ROOT_DIR}/.buildscripts/container.sh" "./.buildscripts/build_image.sh ${BUILD_ARGS[*]}" && \
    "${ROOT_DIR}/.buildscripts/package_rootfs.sh"
else
    "${ROOT_DIR}/.buildscripts/container.sh" "./.buildscripts/build_image.sh" && \
    "${ROOT_DIR}/.buildscripts/package_rootfs.sh"
fi
