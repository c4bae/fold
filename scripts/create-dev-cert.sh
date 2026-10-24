#!/bin/bash
# Creates a self-signed, code-signing-only certificate ("WindowNotch Dev") in the
# login keychain so every build has the same signature and macOS keeps the
# Screen Recording permission across rebuilds. Run once.
#
# The certificate can only sign code (critical EKU codeSigning, keyUsage
# digitalSignature, CA:FALSE) and is trusted only for the code-signing policy.
#
# To remove it later:
#   security delete-identity -c "WindowNotch Dev" ~/Library/Keychains/login.keychain-db
set -euo pipefail
trap 'echo "error: ${BASH_SOURCE[0]} failed at line $LINENO" >&2' ERR

NAME="WindowNotch Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
OPENSSL=/usr/bin/openssl  # LibreSSL; produces a .p12 that `security import` accepts

if [[ "$(security find-identity -p codesigning "$KEYCHAIN")" == *"\"$NAME\""* ]]; then
    echo "Identity \"$NAME\" already exists. Nothing to do."
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/cert.cnf" <<CNF
[ req ]
distinguished_name = dn
prompt             = no
x509_extensions    = ext

[ dn ]
CN = $NAME

[ ext ]
basicConstraints     = critical, CA:FALSE
keyUsage             = critical, digitalSignature
extendedKeyUsage     = critical, codeSigning
subjectKeyIdentifier = hash
CNF

"$OPENSSL" req -x509 -newkey rsa:2048 -nodes -sha256 -days 3650 \
    -config "$WORK/cert.cnf" \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem"

P12_PASS="$("$OPENSSL" rand -hex 16)"
"$OPENSSL" pkcs12 -export -name "$NAME" \
    -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -out "$WORK/identity.p12" -passout "pass:$P12_PASS"

security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$P12_PASS" -T /usr/bin/codesign

echo "Trusting \"$NAME\" for code signing only (macOS may ask for your password)..."
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$WORK/cert.pem"

echo
security find-identity -p codesigning "$KEYCHAIN"
echo "Done."
