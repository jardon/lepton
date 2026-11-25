#!/bin/bash

set -euo pipefail

TESTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $TESTS_DIR/test-common.sh

sed -i "s/_RED=\"\"/_RED=\"RED: \"/g" lepton
sed -i "s/_GREEN=\"\"/_GREEN=\"GREEN: \"/g" lepton
sed -i "s/_PLAIN=\"\"/_PLAIN=\"PLAIN: \"/g" lepton

monitor_logcat general &
LOGCAT_PID="$!"

(./lepton start general || test_log "general container failed to start, test will timeout.") &

wait_for_boot general

./lepton run general getprop ro.lepton.profile
./lepton run general getprop lepton.headless
./lepton run general getprop config.disable_networktime

if [[ "$(./lepton run general getprop ro.lepton.profile 2>/dev/null || true)" != "general" ]]; then
    test_log "general container did not report profile=general."
    test_failure
fi

if [[ "$(./lepton run general getprop lepton.headless 2>/dev/null || true)" != "true" ]]; then
    test_log "general container is not headless."
    test_failure
fi

/usr/lib/android-sdk/platform-tools/adb connect localhost:5555
if ! /usr/lib/android-sdk/platform-tools/adb -s localhost:5555 install tests/test-apk.apk > /dev/null 2>&1; then
    test_log "adb install of test apk failed."
    test_failure
fi

if ! /usr/lib/android-sdk/platform-tools/adb -s localhost:5555 shell "pm list packages com.example.neon42" | grep -q "com.example.neon42"; then
    test_log "test apk did not show up in pm list packages."
    test_failure
fi

/usr/lib/android-sdk/platform-tools/adb -s localhost:5555 shell "am start -n com.example.neon42/.MainActivity" 2>/dev/null || true

wait_for_app general com.example.neon42

if [[ -z "$(./lepton ps | grep "general" | grep "${_GREEN}")" ]]; then
    test_log "general container did not survive app launch."
    test_failure
fi

./lepton stop general

kill "${LOGCAT_PID}"

test_log "general container test finished"