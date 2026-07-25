#!/bin/bash
# Adds the StoreKit configuration to the scheme's TestAction.
#
# XcodeGen 2.46 only emits StoreKitConfigurationFileReference under LaunchAction; it silently
# ignores the key on the test action. Without it on TestAction, `xcodebuild test` runs StoreKit
# in real-App-Store mode and SKTestSession's overrides fail with SKInternalErrorDomain Code=3,
# so every StoreKit test sees zero products.
#
# Run automatically as XcodeGen's postGenCommand, so `xcodegen generate` stays the only step
# anyone has to remember and the generated project is never hand-edited.

set -euo pipefail

SCHEME="DestinyLines.xcodeproj/xcshareddata/xcschemes/DestinyLines.xcscheme"
CONFIG_REF="../../DestinyLines/Resources/Products.storekit"

if [ ! -f "$SCHEME" ]; then
  echo "patch-scheme-storekit: $SCHEME not found" >&2
  exit 1
fi

if grep -q "StoreKitConfigurationFileReference" <(sed -n '/<TestAction/,/<\/TestAction>/p' "$SCHEME"); then
  exit 0
fi

python3 - "$SCHEME" "$CONFIG_REF" <<'PY'
import sys

scheme_path, config_ref = sys.argv[1], sys.argv[2]

with open(scheme_path) as f:
    scheme = f.read()

block = (
    '      <StoreKitConfigurationFileReference\n'
    '         identifier = "%s">\n'
    '      </StoreKitConfigurationFileReference>\n'
    '   </TestAction>' % config_ref
)

if '</TestAction>' not in scheme:
    sys.exit('patch-scheme-storekit: no TestAction in scheme')

scheme = scheme.replace('   </TestAction>', block, 1)

with open(scheme_path, 'w') as f:
    f.write(scheme)
PY

echo "patch-scheme-storekit: added StoreKit config to TestAction"
