# SPDX-License-Identifier: Apache-2.0

# General-purpose Lepton profile.
#
# Unlike the default `game` profile (`aosp_lepton_arm64_only`), this product
# keeps most of the stock AOSP apps and providers that general Android
# applications expect (contacts/media/calendar providers, telecom/telephony
# framework, printing, backup, nfc, vpn, ...) so that arbitrary APKs can be
# installed and run in a persistent container.
#
# The `game` profile stays the default; the remove lists in
# remove_packages/Android.mk are gated on the product name (TARGET_PRODUCT),
# so the `general` profile simply keeps whatever the shared base product
# includes.

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Inherit from the waydroid/lepton device (shared base).
$(call inherit-product, $(LOCAL_PATH)/../device.mk)

PRODUCT_BRAND := Steam-Frame
PRODUCT_DEVICE := lepton_arm64_only
PRODUCT_MANUFACTURER := Lepton
PRODUCT_NAME := general_lepton_arm64_only
PRODUCT_MODEL := Lepton arm64 only General Purpose Device