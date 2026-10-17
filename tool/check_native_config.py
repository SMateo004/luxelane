#!/usr/bin/env python3
"""Checks that the Android and iOS config files parse.

The Android and iOS builds only run on main (or on a Mac); a malformed
manifest, resource or plist would otherwise surface there first.
Run: python3 tool/check_native_config.py
"""
import glob
import plistlib
import sys
import xml.dom.minidom

xml_files = sorted(
    glob.glob('android/app/src/**/AndroidManifest.xml', recursive=True)
    + glob.glob('android/app/src/main/res/**/*.xml', recursive=True)
    + glob.glob('ios/Runner/**/*.storyboard', recursive=True)
)
plists = sorted(glob.glob('ios/Runner/*.plist') + glob.glob('ios/Runner/*.entitlements'))

errors = []
for f in xml_files:
    try:
        xml.dom.minidom.parse(f)
    except Exception as e:  # noqa: BLE001
        errors.append(f'{f}: {e}')
for f in plists:
    try:
        with open(f, 'rb') as fh:
            plistlib.load(fh)
    except Exception as e:  # noqa: BLE001
        errors.append(f'{f}: {e}')

if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'✓ {len(xml_files)} XML and {len(plists)} plist files parse')
